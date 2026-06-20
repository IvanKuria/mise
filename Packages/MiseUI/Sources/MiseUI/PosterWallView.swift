import SwiftUI
import MiseCore
import ThemeKit

/// A responsive wall of posters honoring a `PosterWallStyle`:
/// - `.grid`: uniform adaptive grid.
/// - `.justified`: tighter adaptive grid with smaller gaps (editorial mosaic).
/// - `.shelf`: a single horizontally-scrolling row, like a media shelf.
/// - `.wall`: a dense, gapless adaptive grid (a true wall of posters).
public struct PosterWallView: View {
    @Environment(\.miseTheme) private var theme

    private let films: [Film]
    private let style: PosterWallStyle

    public init(films: [Film], style: PosterWallStyle) {
        self.films = films
        self.style = style
    }

    /// Pure: the target poster width (points) for a wall style.
    public static func posterWidth(for style: PosterWallStyle) -> CGFloat {
        switch style {
        case .grid:      return 130
        case .justified: return 110
        case .shelf:     return 150
        case .wall:      return 92
        }
    }

    /// Pure: the inter-poster gap (points) for a wall style at a density scale.
    public static func gap(for style: PosterWallStyle, densityScale: CGFloat) -> CGFloat {
        let base: CGFloat
        switch style {
        case .grid:      base = 16
        case .justified: base = 8
        case .shelf:     base = 14
        case .wall:      base = 3
        }
        return base * densityScale
    }

    private var posterWidth: CGFloat { Self.posterWidth(for: style) }
    private var gap: CGFloat { Self.gap(for: style, densityScale: MiseTheme.densityScale(theme.density)) }

    public var body: some View {
        Group {
            if films.isEmpty {
                EmptyStateView(
                    symbol: "rectangle.stack",
                    title: "No posters",
                    message: "Films you log will appear here as a poster wall."
                )
            } else if style == .shelf {
                shelf
            } else {
                grid
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: posterWidth), spacing: gap, alignment: .top)]
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: gap) {
            ForEach(films) { film in
                FilmPosterView(film: film, width: posterWidth)
            }
        }
    }

    private var shelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: gap) {
                ForEach(films) { film in
                    FilmPosterView(film: film, width: posterWidth)
                }
            }
            .padding(.vertical, theme.spacing(0.5))
        }
    }
}

#Preview("PosterWallView") {
    ScrollView {
        PosterWallView(films: MiseUIPreviewData.films, style: .grid)
            .padding(32)
    }
    .background(MiseTheme(.noir).background)
    .miseTheme(.noir)
}
