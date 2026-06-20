import SwiftUI
import MiseUI
import MiseCore

/// The first-run experience: a cinematic, centered card floating over a dimmed
/// poster mosaic. The user enters their public Letterboxd handle (and optionally
/// a free TMDB API key) and watches sync progress.
///
/// The host app provides `onSubmit(handle, tmdbKey)` and is responsible for
/// driving `model.status` as the sync proceeds.
public struct OnboardingView: View {
    @Environment(\.miseTheme) private var theme

    @Bindable private var model: OnboardingModel
    private let onSubmit: (String, String?) -> Void

    /// Sample films used to paint the ambient background mosaic.
    private let backdropFilms: [Film]

    public init(
        model: OnboardingModel,
        onSubmit: @escaping (String, String?) -> Void
    ) {
        self._model = Bindable(model)
        self.onSubmit = onSubmit
        self.backdropFilms = MiseUIPreviewData.films
    }

    public var body: some View {
        ZStack {
            background
            card
                .frame(maxWidth: 460)
                .padding(theme.spacing(3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    // MARK: Background mosaic

    private var background: some View {
        ZStack {
            // A dense, gapless wall of posters as ambient texture.
            PosterWallView(films: backdropFilms + backdropFilms, style: .wall)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
                .blur(radius: 8)
                .opacity(0.35)
                .accessibilityHidden(true)

            // A cinematic vignette so the card always reads clearly.
            LinearGradient(
                colors: [
                    theme.background.opacity(0.55),
                    theme.background.opacity(0.92),
                    theme.background,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }

    // MARK: The card

    private var card: some View {
        VStack(spacing: theme.spacing(3)) {
            header
            switch model.status {
            case .syncing(let progress, let message):
                syncing(progress: progress, message: message)
            default:
                form
            }
        }
        .padding(theme.spacing(3.5))
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.posterBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: theme.posterShadow, radius: 30, x: 0, y: 16)
    }

    private var header: some View {
        VStack(spacing: theme.spacing(0.75)) {
            Image(systemName: "film.stack")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(theme.accent)
            Text("Welcome to Mise")
                .font(theme.font(.largeTitle))
                .foregroundStyle(theme.primaryText)
            Text("Enter your public Letterboxd handle to load your films.")
                .font(theme.font(.body))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Form state

    private var form: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            handleField
            tmdbField
            if case .failed(let message) = model.status {
                failureNote(message)
            }
            submitButton
        }
    }

    private var handleField: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
            fieldLabel("Letterboxd handle")
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
            .padding(theme.spacing(1.25))
            .background(fieldBackground)
        }
    }

    private var tmdbField: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
            fieldLabel("TMDB API key — optional")
            SecureField("Paste to enrich posters & metadata", text: $model.tmdbKey)
                .textFieldStyle(.plain)
                .font(theme.font(.mono))
                .foregroundStyle(theme.primaryText)
                .padding(theme.spacing(1.25))
                .background(fieldBackground)
                .onSubmit(submit)
            Text("Free and instant from themoviedb.org. Skip it to start without metadata.")
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryAccent)
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            Text("Load my films")
                .font(theme.font(.headline))
                .foregroundStyle(model.canSubmit ? theme.background : theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing(1.25))
                .background(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                        .fill(model.canSubmit ? theme.accent : theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                        .strokeBorder(theme.posterBorder.opacity(0.6), lineWidth: model.canSubmit ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!model.canSubmit)
        .animation(.easeInOut(duration: 0.15), value: model.canSubmit)
    }

    // MARK: Syncing state

    private func syncing(progress: Double, message: String) -> some View {
        VStack(spacing: theme.spacing(2)) {
            ProgressView(value: progress.clamped01)
                .progressViewStyle(.linear)
                .tint(theme.accent)
            HStack {
                Text(message)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.primaryText)
                Spacer(minLength: theme.spacing())
                Text(progress.percentText)
                    .font(theme.font(.mono))
                    .foregroundStyle(theme.secondaryText)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func failureNote(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing(0.75)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(theme.secondaryAccent)
            Text(message)
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryAccent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Helpers

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(theme.font(.caption))
            .tracking(0.8)
            .foregroundStyle(theme.secondaryText)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
            .fill(theme.background.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                    .strokeBorder(theme.posterBorder.opacity(0.6), lineWidth: 1)
            )
    }

    private func submit() {
        guard let handle = model.normalizedHandle, model.canSubmit else { return }
        onSubmit(handle, model.normalizedTMDBKey)
    }
}

private extension Double {
    /// Clamped into `0...1` for progress display.
    var clamped01: Double { Swift.min(1, Swift.max(0, self)) }

    /// A rounded whole-percent string, e.g. `"42%"`.
    var percentText: String { "\(Int((clamped01 * 100).rounded()))%" }
}

#Preview("Onboarding — idle") {
    OnboardingView(model: OnboardingModel(handle: "davidfincher"), onSubmit: { _, _ in })
        .frame(width: 720, height: 560)
        .miseTheme(.noir)
}

#Preview("Onboarding — syncing") {
    OnboardingView(
        model: OnboardingModel(
            handle: "davidfincher",
            status: .syncing(progress: 0.42, message: "Loading diary…")
        ),
        onSubmit: { _, _ in }
    )
    .frame(width: 720, height: 560)
    .miseTheme(.criterion)
}

#Preview("Onboarding — failed") {
    OnboardingView(
        model: OnboardingModel(
            handle: "davidfincher",
            status: .failed("We couldn't find that handle. Check the spelling and try again.")
        ),
        onSubmit: { _, _ in }
    )
    .frame(width: 720, height: 560)
    .miseTheme(.technicolor)
}
