import SwiftUI
import MiseCore
import MiseUI
import FilmQuery

/// The offline power-browser: a faceted, poster-centric way to slice a diary by
/// rating, genre, decade, runtime, rewatch/liked/review flags, and free text,
/// with a sort menu and a live poster-wall of results.
public struct BrowseView: View {
    @Environment(\.miseTheme) private var theme
    @State private var model: BrowseModel

    public init(entries: [DiaryEntry]) {
        _model = State(initialValue: BrowseModel(entries: entries))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(3)) {
                hero
                card { FilterPanel(model: model) }
                card { resultsSection }
            }
            .padding(theme.spacing(4))
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.clear)
    }

    /// Wraps a section in a translucent card for grouping and depth.
    private func card<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing(2.5))
            .miseCard(theme)
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            Text("YOUR FILMS")
                .font(theme.font(.caption))
                .tracking(2.5)
                .foregroundStyle(theme.accent)
            Text("Browse")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.bottom, theme.spacing(0.5))
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing(1.25)) {
                SectionHeader(countTitle)
                sortMenu
            }

            if !model.activeFilterChips.isEmpty {
                activeFilters
            }

            if model.results.isEmpty {
                EmptyStateView(
                    symbol: "line.3.horizontal.decrease.circle",
                    title: "No films match",
                    message: model.hasActiveFilter
                        ? "Try loosening a filter to see more of your diary."
                        : "Films you log will show up here as a poster wall."
                )
            } else {
                PosterWallView(films: model.resultFilms, style: .grid)
            }
        }
    }

    private var activeFilters: some View {
        FlowLayout(spacing: theme.spacing(0.75)) {
            ForEach(model.activeFilterChips) { chip in
                Button {
                    model.clear(chip.kind)
                } label: {
                    HStack(spacing: theme.spacing(0.375)) {
                        Text(chip.label)
                            .lineLimit(1)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.onSelection)
                    .padding(.horizontal, theme.spacing(1.25))
                    .padding(.vertical, theme.spacing(0.625))
                    .background(Capsule(style: .continuous).fill(theme.selectionFill))
                }
                .buttonStyle(.plain)
                .help("Remove filter")
            }

            Button("Clear all") { model.clearFilters() }
                .buttonStyle(.plain)
                .font(theme.font(.caption))
                .foregroundStyle(theme.textSecondary)
        }
    }

    private var countTitle: String {
        let n = model.resultCount
        let total = model.entries.count
        if model.hasActiveFilter {
            return "\(n) of \(total) film\(total == 1 ? "" : "s")"
        }
        return "\(total) film\(total == 1 ? "" : "s")"
    }

    private var sortMenu: some View {
        Menu {
            ForEach(FilmSort.allCases, id: \.self) { option in
                Button {
                    model.sort = option
                } label: {
                    if model.sort == option {
                        Label(option.displayName, systemImage: "checkmark")
                    } else {
                        Text(option.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: theme.spacing(0.5)) {
                Image(systemName: "arrow.up.arrow.down")
                Text(model.sort.displayName)
                    .lineLimit(1)
            }
            .font(theme.font(.caption))
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, theme.spacing(1.25))
            .padding(.vertical, theme.spacing(0.625))
            .miseField(theme)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

#Preview("BrowseView") {
    BrowseView(entries: MiseUIPreviewData.diary)
        .frame(width: 1000, height: 700)
        .miseTheme(.noir)
}
