import SwiftUI
import MiseUI
import MiseCore
import TasteProfile

/// The aspect ratio / layout variant of the shareable card.
public enum TasteCardVariant: Sendable, Hashable, CaseIterable {
    /// 1:1, ideal for feed posts.
    case square
    /// 9:16, ideal for stories / status.
    case portrait

    /// The canonical pixel size used when exporting at 1x. Renderers scale this up.
    public var canonicalSize: CGSize {
        switch self {
        case .square:   return CGSize(width: 1080, height: 1080)
        case .portrait: return CGSize(width: 1080, height: 1920)
        }
    }

    /// The aspect ratio (width / height).
    public var aspectRatio: CGFloat {
        canonicalSize.width / canonicalSize.height
    }
}

/// THE viral artifact: a beautifully composed, theme-driven "Taste DNA" card.
///
/// It builds a `TasteProfile` from a `WatchHistory` internally, projects it to
/// `TasteCardContent`, and lays it out like a poster / trading card. Designed to
/// be rasterized at a fixed size for sharing (see `TasteCardExporter`), so it
/// renders at a reference width and scales itself to fill whatever frame it's in.
public struct TasteCardView: View {
    @Environment(\.miseTheme) private var theme

    private let content: TasteCardContent
    private let variant: TasteCardVariant

    /// The width the card is designed against; everything scales from here so the
    /// same view looks identical whether shown small on screen or exported large.
    private static let referenceWidth: CGFloat = 540

    public init(history: WatchHistory, variant: TasteCardVariant = .square) {
        self.content = TasteCardContent.make(from: TasteProfileBuilder.build(from: history))
        self.variant = variant
    }

    /// Direct-content initializer, used by previews and the exporter.
    public init(content: TasteCardContent, variant: TasteCardVariant = .square) {
        self.content = content
        self.variant = variant
    }

    public init(profile: TasteProfile, variant: TasteCardVariant = .square) {
        self.content = TasteCardContent.make(from: profile)
        self.variant = variant
    }

    public var body: some View {
        let size = variant.canonicalSize
        GeometryReader { geo in
            let scale = geo.size.width / Self.referenceWidth
            cardBody
                .frame(width: Self.referenceWidth, height: Self.referenceWidth / variant.aspectRatio)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .aspectRatio(variant.aspectRatio, contentMode: .fit)
        .frame(maxWidth: size.width, maxHeight: size.height)
    }

    // MARK: - Composition

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            masthead
            Spacer(minLength: 0)
            hero
            Spacer(minLength: 0)
            if !content.genreChips.isEmpty { genreRow }
            if let line = content.obsessionLine { obsessionView(line) }
            if !content.takeBlurbs.isEmpty { takesView }
            Spacer(minLength: 0)
            if !content.stats.isEmpty { statsGrid }
            footer
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(theme.posterBorder.opacity(0.8), lineWidth: 1.5)
        )
    }

    private var padding: CGFloat {
        variant == .portrait ? 40 : 34
    }

    // MARK: Masthead

    private var masthead: some View {
        HStack(alignment: .center) {
            Text(content.masthead)
                .font(.system(size: 22, weight: .heavy, design: .default))
                .tracking(8)
                .foregroundStyle(theme.primaryText)
            Spacer()
            Text("TASTE DNA")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .overlay(
                    Capsule().strokeBorder(theme.accent.opacity(0.6), lineWidth: 1)
                )
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You are a")
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundStyle(theme.secondaryText)
                .textCase(.uppercase)
                .tracking(2)

            Text(content.archetype)
                .font(heroFont)
                .foregroundStyle(heroGradient)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text(content.tagline)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, variant == .portrait ? 18 : 10)
    }

    private var heroFont: Font {
        let size: CGFloat = variant == .portrait ? 60 : 50
        return .system(size: size, weight: .black, design: .default)
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [theme.primaryText, theme.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Genres

    private var genreRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Defining genres")
            FlowChips(content.genreChips)
        }
        .padding(.bottom, 14)
    }

    // MARK: Obsession

    private func obsessionView(_ line: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "infinity")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.accent)
            Text(line)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.bottom, 12)
    }

    // MARK: Hottest takes

    private var takesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Hottest takes")
            ForEach(content.takeBlurbs, id: \.self) { blurb in
                HStack(alignment: .top, spacing: 8) {
                    Text("“")
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundStyle(theme.accent)
                        .offset(y: 4)
                    Text(blurb)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, 14)
    }

    // MARK: Stats

    private var statsGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: min(content.stats.count, variant == .portrait ? 2 : content.stats.count)
        )
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(content.stats) { stat in
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(stat.label)
                        .font(.system(size: 10, weight: .medium))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(theme.posterBorder.opacity(0.6), lineWidth: 1)
                )
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text(content.footer)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.secondaryText)
            Spacer()
            Circle().fill(theme.accent).frame(width: 6, height: 6)
            Circle().fill(theme.secondaryAccent).frame(width: 6, height: 6)
        }
        .padding(.top, 8)
    }

    // MARK: Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(theme.secondaryText)
    }

    private var cardBackground: some View {
        ZStack {
            theme.background
            // A soft diagonal accent glow that gives the card depth.
            LinearGradient(
                colors: [theme.accent.opacity(0.16), .clear],
                startPoint: .topTrailing,
                endPoint: .center
            )
            RadialGradient(
                colors: [theme.secondaryAccent.opacity(0.12), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 420
            )
        }
    }
}

/// A simple wrapping chip row that lays chips out left-to-right and wraps.
private struct FlowChips: View {
    @Environment(\.miseTheme) private var theme
    private let chips: [String]

    init(_ chips: [String]) { self.chips = chips }

    var body: some View {
        // Two-row HStack wrap good enough for <= 4 chips on a fixed-width card.
        let rows = stride(from: 0, to: chips.count, by: 2).map {
            Array(chips[$0..<min($0 + 2, chips.count)])
        }
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 13, weight: .semibold, design: .default))
                            .foregroundStyle(theme.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous).fill(theme.accent)
                            )
                    }
                }
            }
        }
    }
}

#Preview("Taste Card — Square (Noir)") {
    TasteCardView(content: .preview, variant: .square)
        .miseTheme(.noir)
        .frame(width: 420, height: 420)
        .padding(40)
        .background(Color.black)
}

#Preview("Taste Card — Portrait (Technicolor)") {
    TasteCardView(content: .preview, variant: .portrait)
        .miseTheme(.technicolor)
        .frame(width: 320, height: 569)
        .padding(40)
        .background(Color.black)
}

extension TasteCardContent {
    /// A rich sample for previews and exporter tests.
    static let preview = TasteCardContent(
        archetype: "Auteur Worshipper",
        tagline: "Faithful to the vision",
        masthead: TasteCardContent.masthead,
        genreChips: ["Drama", "Sci-Fi devotee", "Thriller", "Horror"],
        takeBlurbs: [
            "You loved Mandy — the crowd didn't.",
            "You disliked Joker — the crowd loved it.",
        ],
        stats: [
            .init(value: "1,284", label: "Films logged"),
            .init(value: "9.2", label: "Days watching"),
            .init(value: "3.8★", label: "Average rating"),
            .init(value: "Tougher", label: "Critic streak"),
        ],
        obsessionLine: "Keeps returning to David Lynch · 7 films",
        footer: TasteCardContent.footer
    )
}
