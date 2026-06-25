import Foundation
import WebKit

/// An `HTMLFetching` implementation backed by a real browser engine (`WKWebView`).
///
/// Plain `URLSession` sees almost nothing for Letterboxd's `/{user}/films/` grid:
/// the posters are rendered lazily by React, and the page is gated behind
/// Cloudflare's managed JS challenge. A real `WKWebView` renders the React tree
/// *and* executes the Cloudflare challenge script, so reading
/// `document.documentElement.outerHTML` after the page settles yields the fully
/// hydrated markup.
///
/// A single `WKWebView` instance is reused across calls so the warm session and
/// Cloudflare's `cf_clearance` cookie persist in-process. Requests are serialized
/// (one navigation at a time) because the web view is a shared, single-threaded
/// resource.
///
/// ## Swift 6 concurrency
/// `WKWebView` (and its delegate callbacks) are main-actor-only, so the entire
/// class is `@MainActor`-isolated. The `HTMLFetching` protocol is `Sendable` and
/// its `html(for:)` requirement is implemented as a `nonisolated` async function
/// that immediately hops onto the main actor — this lets callers on any executor
/// invoke it while all `WKWebView` access stays on the main actor. The navigation
/// completion is bridged through a `CheckedContinuation` that is stored on, and
/// resumed only from, the main actor, so there are no data races.
@MainActor
public final class WebViewHTMLFetcher: NSObject, HTMLFetching, WKNavigationDelegate {

    // MARK: Tuning

    /// Realistic Safari User-Agent. The default `WKWebView` UA is sometimes
    /// flagged; this matches the value verified to pass Letterboxd/Cloudflare.
    private static let userAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    /// Time to wait after `didFinish` for lazy/JS content + Cloudflare JS to run.
    private static let settleDelay: Duration = .milliseconds(1200)

    /// Extra wait if the first read still looks like a Cloudflare interstitial.
    private static let challengeRetryDelay: Duration = .milliseconds(2500)

    /// Hard ceiling on a single fetch (navigation + settle + read).
    private static let fetchTimeout: Duration = .seconds(20)

    // MARK: Stored state

    /// Lazily created, reused across calls so cookies/session stay warm.
    private var _webView: WKWebView?

    /// Continuation for the in-flight navigation, resumed from delegate callbacks.
    /// Stored and mutated only on the main actor.
    private var navigationContinuation: CheckedContinuation<Void, Error>?

    /// Serializes fetches so concurrent callers don't clobber the shared web view.
    /// Each call awaits the previous call's task before driving a navigation.
    private var pendingTail: Task<Void, Never>?

    // MARK: Init

    public override init() {
        super.init()
    }

    // MARK: HTMLFetching

    /// Loads `url` in the shared web view, waits for the page (and Cloudflare JS)
    /// to settle, then returns the fully rendered `outerHTML`.
    ///
    /// `nonisolated` so it satisfies the `Sendable` protocol requirement and can be
    /// called from any executor; the body hops to the main actor immediately.
    public nonisolated func html(for url: URL) async throws -> String {
        try await self.serialized { fetcher in
            try await fetcher.fetchOnMain(url)
        }
    }

    // MARK: Serialization

    /// Runs `body` after any previously enqueued fetch completes, guaranteeing a
    /// single navigation at a time over the shared web view. All access to the
    /// queue tail happens on the main actor.
    private func serialized(_ body: @escaping @MainActor (WebViewHTMLFetcher) async throws -> String) async throws -> String {
        // Capture the previous tail, then install a continuation that callers
        // waiting behind us can await.
        let previous = pendingTail
        let gate = AsyncGate()
        pendingTail = Task { @MainActor in await gate.wait() }

        // Wait for everyone ahead of us to finish.
        await previous?.value

        defer { gate.open() }
        return try await body(self)
    }

    // MARK: Web view

    /// Builds (once) and returns the shared, configured `WKWebView`.
    private func webView() -> WKWebView {
        if let existing = _webView { return existing }

        let config = WKWebViewConfiguration()
        // Default (persistent) store keeps cookies like `cf_clearance` warm for
        // the lifetime of the process.
        config.websiteDataStore = .default()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let view = WKWebView(frame: .zero, configuration: config)
        view.customUserAgent = Self.userAgent
        view.navigationDelegate = self
        _webView = view
        return view
    }

    // MARK: Core fetch (main actor)

    /// Performs one full navigation + read cycle on the main actor with a hard
    /// timeout. Assumes the caller has already serialized access.
    private func fetchOnMain(_ url: URL) async throws -> String {
        let view = webView()

        // Navigation is bounded by an internal timer in loadAndWait; the post-load
        // steps are bounded by their fixed settle delays.
        try await loadAndWait(view, url: url)

        // Let lazy React content + Cloudflare JS settle, then read.
        try? await Task.sleep(for: Self.settleDelay)
        var rendered = try await self.outerHTML(of: view, url: url)

        // If still on a Cloudflare interstitial, wait once more and re-read.
        if Self.looksLikeChallenge(rendered) {
            try? await Task.sleep(for: Self.challengeRetryDelay)
            rendered = try await self.outerHTML(of: view, url: url)
        }

        return rendered
    }

    /// Starts a navigation and suspends until `didFinish` / `didFail` fires.
    private func loadAndWait(_ view: WKWebView, url: URL) async throws {
        // A navigation should never already be in flight here (serialized), but
        // be defensive: fail any stale continuation rather than leaking it.
        if let stale = navigationContinuation {
            navigationContinuation = nil
            stale.resume(throwing: CancellationError())
        }

        var request = URLRequest(url: url)
        request.setValue(
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            navigationContinuation = continuation
            view.load(request)
            // Hard navigation timeout (main-queue timer). Whichever of the timer
            // or a delegate callback fires first nils `navigationContinuation`;
            // the loser sees nil and is a no-op, so the continuation resumes once.
            let seconds = Double(Self.fetchTimeout.components.seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
                guard let self, self.navigationContinuation != nil else { return }
                self.navigationContinuation = nil
                view.stopLoading()
                continuation.resume(throwing: ScrapeError.httpStatus(408, url: url))
            }
        }
    }

    /// Evaluates `document.documentElement.outerHTML` and returns it as a string.
    private func outerHTML(of view: WKWebView, url: URL) async throws -> String {
        let result = try await view.evaluateJavaScript("document.documentElement.outerHTML")
        guard let html = result as? String else {
            throw ScrapeError.notText(url: url)
        }
        return html
    }

    // MARK: Challenge detection

    /// Heuristic for a Cloudflare interstitial still being shown.
    private static func looksLikeChallenge(_ html: String) -> Bool {
        html.contains("Just a moment")
            || html.contains("cf-challenge")
            || html.contains("Checking your browser")
    }

    // MARK: WKNavigationDelegate

    public nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in self.resumeNavigation(with: nil) }
    }

    public nonisolated func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor in self.resumeNavigation(with: error) }
    }

    public nonisolated func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor in self.resumeNavigation(with: error) }
    }

    /// Resumes (and clears) the pending navigation continuation exactly once.
    private func resumeNavigation(with error: Error?) {
        guard let continuation = navigationContinuation else { return }
        navigationContinuation = nil
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}

/// A one-shot async gate used to serialize fetches. Callers `await wait()` until
/// the holder calls `open()`. Isolated to the main actor to match the fetcher.
@MainActor
private final class AsyncGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var opened = false

    func wait() async {
        if opened { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            if opened {
                c.resume()
            } else {
                continuation = c
            }
        }
    }

    func open() {
        guard !opened else { return }
        opened = true
        continuation?.resume()
        continuation = nil
    }
}
