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
        HStack(alignment: .top, spacing: 0) {
            FilterPanel(model: model)
                .frame(width: 280)
                .background(theme.surface.opacity(0.4))

            Divider().overlay(theme.posterBorder)

            resultsColumn
        }
        .background(theme.background)
    }

    private var resultsColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            resultsHeader
                .padding(.horizontal, theme.spacing(2))
                .padding(.top, theme.spacing(2))
                .padding(.bottom, theme.spacing(1.5))

            Divider().overlay(theme.posterBorder)

            if model.results.isEmpty {
                EmptyStateView(
                    symbol: "line.3.horizontal.decrease.circle",
                    title: "No films match",
                    message: model.hasActiveFilter
                        ? "Try loosening a filter to see more of your diary."
                        : "Films you log will show up here as a poster wall."
                )
            } else {
                ScrollView {
                    PosterWallView(films: model.resultFilms, style: .grid)
                        .padding(theme.spacing(2))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var resultsHeader: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.25)) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader("Browse", subtitle: countSubtitle)
                Spacer(minLength: theme.spacing())
                sortMenu
            }

            if !model.activeFilterChips.isEmpty {
                FlowLayout(spacing: theme.spacing(0.75)) {
                    ForEach(model.activeFilterChips) { chip in
                        Button {
                            model.clear(chip.kind)
                        } label: {
                            HStack(spacing: theme.spacing(0.375)) {
                                Text(chip.label)
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.background)
                            .padding(.horizontal, theme.spacing(1.25))
                            .padding(.vertical, theme.spacing(0.625))
                            .background(Capsule(style: .continuous).fill(theme.accent))
                        }
                        .buttonStyle(.plain)
                        .help("Remove filter")
                    }

                    Button("Clear all") { model.clearFilters() }
                        .buttonStyle(.plain)
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryAccent)
                }
            }
        }
    }

    private var countSubtitle: String {
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
            }
            .font(theme.font(.caption))
            .foregroundStyle(theme.primaryText)
            .padding(.horizontal, theme.spacing(1.25))
            .padding(.vertical, theme.spacing(0.625))
            .background(
                Capsule(style: .continuous).fill(theme.surface)
            )
            .overlay(
                Capsule(style: .continuous).strokeBorder(theme.posterBorder, lineWidth: 1)
            )
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
