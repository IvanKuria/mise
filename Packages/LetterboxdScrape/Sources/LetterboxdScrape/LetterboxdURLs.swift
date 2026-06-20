import Foundation

/// Builds the public Letterboxd URLs we scrape. All pages are keyed by handle.
enum LetterboxdURLs {
    static let base = URL(string: "https://letterboxd.com")!

    static func profile(_ username: String) -> URL {
        base.appending(path: "\(username)/")
    }

    /// The canonical diary path. NOTE: `/{user}/films/diary/` is Cloudflare-
    /// challenged for unauthenticated clients, but `/{user}/diary/` returns 200.
    static func diary(_ username: String, page: Int = 1) -> URL {
        paged("\(username)/diary/", page: page)
    }

    static func films(_ username: String, page: Int = 1) -> URL {
        paged("\(username)/films/", page: page)
    }

    static func watchlist(_ username: String, page: Int = 1) -> URL {
        paged("\(username)/watchlist/", page: page)
    }

    static func lists(_ username: String, page: Int = 1) -> URL {
        paged("\(username)/lists/", page: page)
    }

    /// Resolve an href found in the HTML (which may be absolute or root-relative).
    static func resolve(_ href: String) -> URL? {
        if href.hasPrefix("http") { return URL(string: href) }
        return URL(string: href, relativeTo: base)?.absoluteURL
    }

    private static func paged(_ path: String, page: Int) -> URL {
        let full = page <= 1 ? path : "\(path)page/\(page)/"
        return base.appending(path: full)
    }
}
