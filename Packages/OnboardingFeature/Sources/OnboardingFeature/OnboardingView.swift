import SwiftUI
import MiseUI

/// First-run experience, styled as a printed repertory-cinema program: a framed
/// paper card with a catalogue header, editorial display type, and ledger-style
/// fields. The host app provides `onSubmit(handle, tmdbKey)` and drives
/// `model.status` as the sync proceeds.
public struct OnboardingView: View {
    @Environment(\.miseTheme) private var theme

    @Bindable private var model: OnboardingModel
    private let onSubmit: (String, String?) -> Void

    public init(
        model: OnboardingModel,
        onSubmit: @escaping (String, String?) -> Void
    ) {
        self._model = Bindable(model)
        self.onSubmit = onSubmit
    }

    public var body: some View {
        ZStack {
            paper
            program
                .frame(maxWidth: 540)
                .padding(theme.spacing(4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    // MARK: Paper ground

    private var paper: some View {
        LinearGradient(
            colors: [
                theme.surface,
                theme.background,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            // A faint warm bloom at the top, like a page under a reading lamp.
            RadialGradient(
                colors: [theme.secondaryAccent.opacity(0.10), .clear],
                center: .top, startRadius: 0, endRadius: 460
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: The program card

    private var program: some View {
        VStack(alignment: .leading, spacing: 0) {
            masthead
            DoubleRule(color: theme.primaryText)
                .padding(.top, theme.spacing(1.5))
                .padding(.bottom, theme.spacing(2.5))

            Group {
                if case .syncing(let progress, let message) = model.status {
                    syncing(progress: progress, message: message)
                } else {
                    formBody
                }
            }

            colophon
                .padding(.top, theme.spacing(3))
        }
        .padding(theme.spacing(4))
        .background(theme.surface)
        .overlay(
            Rectangle().strokeBorder(theme.primaryText.opacity(0.85), lineWidth: 1)
        )
        .overlay(
            // Inner hairline, the second rule of a printed cover.
            Rectangle()
                .strokeBorder(theme.primaryText.opacity(0.35), lineWidth: 1)
                .padding(5)
        )
        .shadow(color: theme.posterShadow, radius: 28, x: 0, y: 18)
    }

    private var masthead: some View {
        HStack(alignment: .center, spacing: theme.spacing(1.5)) {
            FilmFrameMark(color: theme.primaryText)
                .frame(width: 26, height: 34)
            Text("MISE")
                .font(theme.font(.largeTitle))
                .tracking(2)
                .foregroundStyle(theme.primaryText)
            Spacer(minLength: 0)
            Text("UNOFFICIAL\nLETTERBOXD ALMANAC")
                .font(theme.font(.caption))
                .tracking(1.5)
                .lineSpacing(2)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(theme.secondaryText)
        }
    }

    // MARK: Form

    private var formBody: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2.5)) {
            VStack(alignment: .leading, spacing: theme.spacing(1)) {
                Text("NO. 001 · FIRST EDITION")
                    .font(theme.font(.caption))
                    .tracking(2)
                    .foregroundStyle(theme.accent)
                Text("Your films,\ncatalogued.")
                    .font(theme.font(.largeTitle))
                    .lineSpacing(2)
                    .foregroundStyle(theme.primaryText)
                Text("Enter a public Letterboxd handle. Mise reads your diary, ratings, and watchlist into a private archive that lives on your Mac.")
                    .font(theme.font(.body))
                    .lineSpacing(3)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: theme.spacing(2)) {
                handleField
                tmdbField
            }

            if case .failed(let message) = model.status {
                failureNote(message)
            }

            submitButton
        }
    }

    private var handleField: some View {
        ledgerField(label: "Letterboxd handle") {
            HStack(spacing: theme.spacing(0.5)) {
                Text("letterboxd.com/")
                    .font(theme.font(.mono))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .layoutPriority(-1)
                TextField("yourname", text: $model.handle)
                    .textFieldStyle(.plain)
                    .font(theme.font(.mono))
                    .foregroundStyle(theme.primaryText)
                    .onSubmit(submit)
            }
        }
    }

    private var tmdbField: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            ledgerField(label: "The Movie Database key — optional") {
                SecureField("paste to unlock posters", text: $model.tmdbKey)
                    .textFieldStyle(.plain)
                    .font(theme.font(.mono))
                    .foregroundStyle(theme.primaryText)
                    .onSubmit(submit)
            }
            Text("Unlocks posters, genres & runtimes. Free and instant at themoviedb.org.")
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: theme.spacing(1)) {
                Text("Load my films")
                    .font(theme.font(.headline))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(theme.surface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing(1.5))
            .background(model.canSubmit ? theme.accent : theme.secondaryText.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!model.canSubmit)
        .animation(.easeInOut(duration: 0.15), value: model.canSubmit)
    }

    // MARK: Syncing

    private func syncing(progress: Double, message: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            Text("NOW READING")
                .font(theme.font(.caption))
                .tracking(2)
                .foregroundStyle(theme.accent)
            Text(message)
                .font(theme.font(.title))
                .foregroundStyle(theme.primaryText)
            ProgressBar(value: progress, track: theme.primaryText.opacity(0.15), fill: theme.accent)
                .frame(height: 3)
            Text(progress.percentText + " catalogued")
                .font(theme.font(.mono))
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func failureNote(_ message: String) -> some View {
        Text(message)
            .font(theme.font(.body))
            .foregroundStyle(theme.accent)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing(1.25))
            .overlay(Rectangle().strokeBorder(theme.accent.opacity(0.5), lineWidth: 1))
    }

    private var colophon: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.25)) {
            Rule(color: theme.primaryText.opacity(0.25))
            Text("MISE · MMXXVI — NOT AFFILIATED WITH LETTERBOXD")
                .font(theme.font(.caption))
                .tracking(1.5)
                .foregroundStyle(theme.secondaryText)
        }
    }

    // MARK: Helpers

    private func ledgerField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            Text(label.uppercased())
                .font(theme.font(.caption))
                .tracking(1.5)
                .foregroundStyle(theme.secondaryText)
            content()
                .padding(.vertical, theme.spacing(1))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(theme.primaryText.opacity(0.5))
                        .frame(height: 1)
                }
        }
    }

    private func submit() {
        guard let handle = model.normalizedHandle, model.canSubmit else { return }
        onSubmit(handle, model.normalizedTMDBKey)
    }
}

// MARK: - Signature marks & rules

/// A small drawn filmstrip — the app's mark, deliberately not an SF Symbol.
private struct FilmFrameMark: View {
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let stripInset = w * 0.22
            // Frame outline.
            ctx.stroke(
                Path(CGRect(x: 0.5, y: 0.5, width: w - 1, height: h - 1)),
                with: .color(color), lineWidth: 1.2
            )
            // Sprocket holes down both edges.
            let holeW = stripInset * 0.5
            let holeH = h / 9
            for i in 0..<4 {
                let y = h * (0.12 + Double(i) * 0.25)
                for x in [stripInset * 0.25, w - stripInset * 0.75] {
                    ctx.fill(
                        Path(roundedRect: CGRect(x: x, y: y, width: holeW, height: holeH), cornerRadius: 1),
                        with: .color(color)
                    )
                }
            }
            // Central frame line.
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: stripInset, y: h / 2))
                    p.addLine(to: CGPoint(x: w - stripInset, y: h / 2))
                },
                with: .color(color.opacity(0.5)), lineWidth: 1
            )
        }
        .accessibilityHidden(true)
    }
}

/// A single printed hairline.
private struct Rule: View {
    var color: Color
    var body: some View { Rectangle().fill(color).frame(height: 1) }
}

/// A printed double rule (thick over thin), like a program cover.
private struct DoubleRule: View {
    var color: Color
    var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(color.opacity(0.85)).frame(height: 2)
            Rectangle().fill(color.opacity(0.5)).frame(height: 1)
        }
    }
}

/// A flat, square-cornered progress bar (no rounded chrome) in the printed style.
private struct ProgressBar: View {
    var value: Double
    var track: Color
    var fill: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                Rectangle().fill(fill)
                    .frame(width: geo.size.width * value.clamped01)
            }
        }
    }
}

private extension Double {
    var clamped01: Double { Swift.min(1, Swift.max(0, self)) }
    var percentText: String { "\(Int((clamped01 * 100).rounded()))%" }
}

#Preview("Onboarding — idle") {
    OnboardingView(model: OnboardingModel(handle: "davidfincher"), onSubmit: { _, _ in })
        .frame(width: 820, height: 680)
        .miseTheme(.repertory)
}

#Preview("Onboarding — syncing") {
    OnboardingView(
        model: OnboardingModel(
            handle: "davidfincher",
            status: .syncing(progress: 0.42, message: "Reading the diary…")
        ),
        onSubmit: { _, _ in }
    )
    .frame(width: 820, height: 680)
    .miseTheme(.repertory)
}
