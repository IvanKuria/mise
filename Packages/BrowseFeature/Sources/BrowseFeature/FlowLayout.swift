import SwiftUI

/// A simple left-to-right wrapping layout (a "flow" / tag cloud) used for chip
/// rows that should wrap to multiple lines within their available width.
struct FlowLayout: Layout {
    var spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: width, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height + (partial > 0 ? spacing : 0)
        }
        let maxRowWidth = rows.reduce(CGFloat.zero) { Swift.max($0, $1.width) }
        return CGSize(width: proposal.width ?? maxRowWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
        var width: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : x + spacing + size.width
            if !current.indices.isEmpty && needed > maxWidth {
                rows.append(current)
                current = Row()
                x = 0
            }
            x = current.indices.isEmpty ? size.width : x + spacing + size.width
            current.indices.append(index)
            current.height = max(current.height, size.height)
            current.width = x
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
