import SwiftUI
import MiseCore
import MiseUI
import WatchlistPlanner

/// The editable constraints for tonight: ranking, runtime cap, services, genres,
/// and a minimum rating floor. Selecting any control re-solves the pick live.
struct CriteriaControls: View {
    @Environment(\.miseTheme) private var theme
    @Bindable var model: WatchlistModel

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader("Your mood")
                Spacer()
                if model.hasActiveCriteria {
                    Button("Clear") { model.clearCriteria() }
                        .buttonStyle(.plain)
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.accent)
                }
            }

            rankingControl

            runtimeControl

            if !model.availableServices.isEmpty {
                serviceControl
            }

            if !model.availableGenres.isEmpty {
                genreControl
            }

            ratingControl
        }
        .padding(theme.spacing(2.5))
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.posterBorder.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: Ranking

    private var rankingControl: some View {
        labeledRow("Choose by") {
            ChipRow {
                chip("Surprise me", selected: model.ranking.isRandom) {
                    model.ranking = .random(seed: 0)
                }
                chip("Shortest", selected: model.ranking == .shortestFirst) {
                    model.ranking = .shortestFirst
                }
                chip("Highest rated", selected: model.ranking == .highestRated) {
                    model.ranking = .highestRated
                }
            }
        }
    }

    // MARK: Runtime

    private var runtimeControl: some View {
        labeledRow("Max runtime") {
            ChipRow {
                chip("Any", selected: model.maxRuntimeMinutes == nil) {
                    model.maxRuntimeMinutes = nil
                }
                ForEach(model.runtimeOptions, id: \.self) { cap in
                    chip("≤ \(cap)m", selected: model.maxRuntimeMinutes == cap) {
                        model.maxRuntimeMinutes = (model.maxRuntimeMinutes == cap) ? nil : cap
                    }
                }
            }
        }
    }

    // MARK: Services

    private var serviceControl: some View {
        labeledRow("On") {
            ChipRow {
                ForEach(model.availableServices, id: \.self) { service in
                    chip(service, selected: model.selectedServices.contains(service)) {
                        model.toggleService(service)
                    }
                }
            }
        }
    }

    // MARK: Genres

    private var genreControl: some View {
        labeledRow("Genre") {
            ChipRow {
                ForEach(model.availableGenres, id: \.self) { genre in
                    chip(genre, selected: model.selectedGenres.contains(genre)) {
                        model.toggleGenre(genre)
                    }
                }
            }
        }
    }

    // MARK: Rating

    private var ratingControl: some View {
        labeledRow("At least") {
            ChipRow {
                chip("Any", selected: model.minAverage == nil) {
                    model.minAverage = nil
                }
                ForEach(model.minAverageOptions, id: \.self) { value in
                    chip(String(format: "%.1f★", value), selected: model.minAverage == value) {
                        model.minAverage = (model.minAverage == value) ? nil : value
                    }
                }
            }
        }
    }

    // MARK: Building blocks

    private func labeledRow<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            Text(label.uppercased())
                .font(theme.font(.caption))
                .tracking(0.8)
                .foregroundStyle(theme.secondaryText)
            content()
        }
    }

    private func chip(
        _ text: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Chip(text, selected: selected)
        }
        .buttonStyle(.plain)
    }
}

/// A simple wrapping row of chips.
private struct ChipRow<Content: View>: View {
    @Environment(\.miseTheme) private var theme
    @ViewBuilder var content: Content

    var body: some View {
        FlowLayout(spacing: theme.spacing(0.75)) {
            content
        }
    }
}

/// A minimal flow layout so chips wrap to new lines instead of clipping.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = layout(subviews: subviews, maxWidth: maxWidth)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map { row in row.frames.map { $0.maxX }.max() ?? 0 }.max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = layout(subviews: subviews, maxWidth: bounds.width)
        for row in rows {
            for (index, frame) in zip(row.indices, row.frames) {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                    proposal: ProposedViewSize(width: frame.width, height: frame.height)
                )
            }
        }
    }

    private struct Row {
        var y: CGFloat
        var height: CGFloat
        var indices: [Int]
        var frames: [CGRect]
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var indices: [Int] = []
        var frames: [CGRect] = []

        func flush() {
            rows.append(Row(y: y, height: rowHeight, indices: indices, frames: frames))
            y += rowHeight + spacing
            x = 0
            rowHeight = 0
            indices = []
            frames = []
        }

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                flush()
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            indices.append(index)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        if !indices.isEmpty { flush() }

        // Normalize frame y to be relative within the layout (rows already use y).
        return rows
    }
}

private extension Ranking {
    var isRandom: Bool {
        if case .random = self { return true }
        return false
    }
}
