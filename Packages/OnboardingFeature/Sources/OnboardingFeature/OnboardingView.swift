import SwiftUI
import MiseUI

/// First-run experience: a cinematic dark room where a rounded hero card (a
/// fanned stack of poster cards) carries the color. The host app provides
/// `onSubmit(handle, tmdbKey)` and drives `model.status` as the sync proceeds.
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
            backdrop
            VStack(spacing: theme.spacing(2.5)) {
                hero
                content
                    .frame(maxWidth: 420)
            }
            .padding(theme.spacing(3.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    // MARK: Backdrop

    private var backdrop: some View {
        LinearGradient(
            colors: [theme.surface, theme.background],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(alignment: .top) {
            RadialGradient(
                colors: [theme.accent.opacity(0.14), .clear],
                center: .top, startRadius: 0, endRadius: 520
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: Hero — a fanned stack of poster cards

    private var hero: some View {
        ZStack {
            posterCard(tint: theme.secondaryAccent, rotation: -10, offset: CGSize(width: -86, height: 8))
            posterCard(tint: theme.secondaryText, rotation: 8, offset: CGSize(width: 84, height: 10))
            posterCard(tint: theme.accent, rotation: 0, offset: .zero, front: true)
        }
        .frame(height: 150)
        .padding(.top, theme.spacing(2))
        .accessibilityHidden(true)
    }

    private func posterCard(tint: Color, rotation: Double, offset: CGSize, front: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(tint)
            .frame(width: 104, height: 150)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.18), .clear],
                        startPoint: .topLeading, endPoint: .bottom
                    ))
            )
            .overlay(alignment: .bottomLeading) {
                if front {
                    MiseMark(color: theme.background)
                        .frame(width: 22, height: 22)
                        .padding(12)
                }
            }
            .shadow(color: theme.posterShadow, radius: 18, x: 0, y: 12)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: theme.spacing(3)) {
            VStack(alignment: .leading, spacing: theme.spacing(1.25)) {
                Text("WELCOME TO MISE")
                    .font(theme.font(.caption))
                    .tracking(2)
                    .foregroundStyle(theme.accent)
                Text("Bring your films\nhome.")
                    .font(.custom("Bricolage Grotesque", size: 33).weight(.bold))
                    .foregroundStyle(theme.primaryText)
                    .lineSpacing(2)
                Text("Enter a public Letterboxd handle. Mise builds a private archive of your diary, ratings, and watchlist — right on your Mac.")
                    .font(theme.font(.body))
                    .foregroundStyle(theme.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if case .syncing(let progress, let message) = model.status {
                syncing(progress: progress, message: message)
            } else {
                form
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            field(label: "Letterboxd handle") {
                HStack(spacing: 2) {
                    Text("letterboxd.com/")
                        .foregroundStyle(theme.secondaryText)
                        .layoutPriority(-1)
                    TextField("yourname", text: $model.handle)
                        .textFieldStyle(.plain)
                        .foregroundStyle(theme.primaryText)
                        .onSubmit(submit)
                }
                .font(theme.font(.body))
            }

            field(label: "TMDB key — optional, unlocks posters") {
                SecureField("paste to enrich", text: $model.tmdbKey)
                    .textFieldStyle(.plain)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.primaryText)
                    .onSubmit(submit)
            }

            if case .failed(let message) = model.status {
                Text(message)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.secondaryAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            submitButton
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: theme.spacing(1)) {
                Text("Load my films").font(theme.font(.headline))
                Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(theme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing(1.75))
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(model.canSubmit ? theme.accent : theme.secondaryText.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
        .disabled(!model.canSubmit)
        .animation(.easeInOut(duration: 0.15), value: model.canSubmit)
        .padding(.top, theme.spacing(0.5))
    }

    private func syncing(progress: Double, message: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            Text(message)
                .font(theme.font(.headline))
                .foregroundStyle(theme.primaryText)
            ProgressBar(value: progress, track: theme.primaryText.opacity(0.14), fill: theme.accent)
                .frame(height: 6)
            Text(progress.percentText + " catalogued")
                .font(theme.font(.mono))
                .foregroundStyle(theme.secondaryText)
        }
        .padding(theme.spacing(2.5))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.surface)
        )
    }

    // MARK: Helpers

    private func field<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            Text(label.uppercased())
                .font(theme.font(.caption))
                .tracking(1.5)
                .foregroundStyle(theme.secondaryText)
            content()
                .padding(.horizontal, theme.spacing(1.75))
                .padding(.vertical, theme.spacing(1.5))
                .background(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                        .fill(theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                        .strokeBorder(theme.posterBorder, lineWidth: 1)
                )
        }
    }

    private func submit() {
        guard let handle = model.normalizedHandle, model.canSubmit else { return }
        onSubmit(handle, model.normalizedTMDBKey)
    }
}

/// The app mark: a 2×2 grid of rounded squares (echoing a contact sheet / poster
/// grid). Deliberately drawn, not an SF Symbol.
struct MiseMark: View {
    var color: Color
    var body: some View {
        GeometryReader { geo in
            let g = geo.size.width * 0.16
            let s = (geo.size.width - g) / 2
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: s * 0.28, style: .continuous)
                        .fill(color)
                        .frame(width: s, height: s)
                        .offset(
                            x: (i % 2 == 0 ? 0 : s + g) - (s + g) / 2,
                            y: (i < 2 ? 0 : s + g) - (s + g) / 2
                        )
                        .opacity(i == 1 ? 0.55 : 1)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ProgressBar: View {
    var value: Double
    var track: Color
    var fill: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(fill).frame(width: geo.size.width * value.clamped01)
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
        .frame(width: 860, height: 760)
        .miseTheme(.marquee)
}

#Preview("Onboarding — syncing") {
    OnboardingView(
        model: OnboardingModel(
            handle: "davidfincher",
            status: .syncing(progress: 0.42, message: "Reading the diary…")
        ),
        onSubmit: { _, _ in }
    )
    .frame(width: 860, height: 760)
    .miseTheme(.marquee)
}
