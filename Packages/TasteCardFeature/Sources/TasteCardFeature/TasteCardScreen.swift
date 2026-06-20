import SwiftUI
import MiseUI
import MiseCore
import ThemeKit
import TasteProfile

#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

/// A surrounding screen that previews the card, lets the user pick a share
/// variant, and exports / saves the rendered PNG via `TasteCardExporter`.
public struct TasteCardScreen: View {
    @Environment(\.miseTheme) private var theme

    private let profile: TasteProfile
    private let resolvedTheme: Theme

    @State private var variant: TasteCardVariant = .square
    @State private var isExporting = false

    public init(history: WatchHistory, theme: Theme = .noir) {
        self.profile = TasteProfileBuilder.build(from: history)
        self.resolvedTheme = theme
    }

    public init(profile: TasteProfile, theme: Theme = .noir) {
        self.profile = profile
        self.resolvedTheme = theme
    }

    public var body: some View {
        VStack(spacing: theme.spacing(2)) {
            TasteCardView(profile: profile, variant: variant)
                .frame(maxWidth: 460, maxHeight: 700)
                .shadow(color: theme.posterShadow, radius: 24, y: 12)

            Picker("Format", selection: $variant) {
                Text("Square").tag(TasteCardVariant.square)
                Text("Portrait").tag(TasteCardVariant.portrait)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)

            Button {
                export()
            } label: {
                Label(isExporting ? "Exporting…" : "Export PNG", systemImage: "square.and.arrow.up")
                    .font(theme.font(.headline))
                    .padding(.horizontal, theme.spacing(2))
                    .padding(.vertical, theme.spacing(1))
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(isExporting)
        }
        .padding(theme.spacing(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    @MainActor
    private func export() {
        #if canImport(AppKit)
        isExporting = true
        defer { isExporting = false }

        let size = variant.canonicalSize
        let exporter = TasteCardExporter()
        guard let data = exporter.pngData(for: profile, theme: resolvedTheme, size: size, scale: 1.0) else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "taste-dna.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
        #endif
    }
}

#Preview("Taste Card Screen") {
    TasteCardScreen(profile: previewProfile, theme: .technicolor)
        .miseTheme(.technicolor)
        .frame(width: 640, height: 820)
}

/// A profile-shaped sample for the screen preview.
private let previewProfile = TasteProfile(
    archetype: "Arthouse Contrarian",
    definingGenres: [
        DefiningGenre(name: "Drama", count: 120, share: 0.4, lift: 2.1, label: "Drama devotee"),
        DefiningGenre(name: "Thriller", count: 60, share: 0.2, lift: 1.5, label: "Thriller"),
        DefiningGenre(name: "Horror", count: 40, share: 0.13, lift: 1.4, label: "Horror"),
    ],
    hottestTakes: [
        HottestTake(filmID: "1", filmName: "Mandy", memberStars: 5, communityStars: 3, delta: 2, direction: .lovedItCrowdDidnt, blurb: "You loved Mandy — the crowd didn't."),
        HottestTake(filmID: "2", filmName: "Joker", memberStars: 2, communityStars: 4, delta: -2, direction: .dislikedItCrowdLoved, blurb: "You disliked Joker — the crowd loved it."),
    ],
    obsessions: [
        Obsession(kind: .director, key: "p1", name: "David Lynch", count: 7, label: "7 films"),
    ],
    blindSpots: [],
    headlineStats: [
        HeadlineStat(key: "filmsLogged", label: "Films logged", value: "1,284"),
        HeadlineStat(key: "daysOfRuntime", label: "Days watching", value: "9.2"),
        HeadlineStat(key: "averageRating", label: "Average rating", value: "3.8★"),
        HeadlineStat(key: "contrarian", label: "Critic streak", value: "Tougher than most"),
    ]
)
