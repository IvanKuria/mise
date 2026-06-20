import SwiftUI
import MiseCore
import MiseUI
import FilmQuery

/// The left-hand filter controls, driven entirely by the model's available facets.
struct FilterPanel: View {
    @Environment(\.miseTheme) private var theme
    @Bindable var model: BrowseModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(2.5)) {
                searchSection
                ratingSection
                if !facets.genres.isEmpty { genreSection }
                if !facets.decades.isEmpty { decadeSection }
                if let runtime = facets.runtimeRange, runtime.lowerBound < runtime.upperBound {
                    runtimeSection(bounds: runtime)
                }
                togglesSection
            }
            .padding(theme.spacing(2))
        }
    }

    private var facets: Facets { model.facets }

    // MARK: Search

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            label("Search")
            HStack(spacing: theme.spacing(0.5)) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.secondaryText)
                TextField(
                    "",
                    text: Binding(
                        get: { model.filter.freeText ?? "" },
                        set: { model.setSearch($0) }
                    ),
                    prompt: Text("Title…").foregroundStyle(theme.secondaryText)
                )
                .textFieldStyle(.plain)
                .foregroundStyle(theme.primaryText)
            }
            .font(theme.font(.body))
            .padding(.horizontal, theme.spacing(1))
            .padding(.vertical, theme.spacing(0.75))
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

    // MARK: Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            label("Rating")
            let lo = model.filter.ratingRange?.lowerBound.halfStars ?? 1
            let hi = model.filter.ratingRange?.upperBound.halfStars ?? 10
            HStack(spacing: theme.spacing(0.5)) {
                stepperPill(
                    title: "Min",
                    value: lo,
                    decrement: { model.setRatingRange(minHalfStars: max(1, lo - 1), maxHalfStars: max(hi, lo - 1)) },
                    increment: { model.setRatingRange(minHalfStars: min(hi, lo + 1), maxHalfStars: hi) }
                )
                stepperPill(
                    title: "Max",
                    value: hi,
                    decrement: { model.setRatingRange(minHalfStars: min(lo, hi - 1), maxHalfStars: max(lo, hi - 1)) },
                    increment: { model.setRatingRange(minHalfStars: lo, maxHalfStars: min(10, hi + 1)) }
                )
            }
            if model.filter.ratingRange != nil {
                clearButton { model.setRatingRange(minHalfStars: nil, maxHalfStars: nil) }
            }
        }
    }

    private func stepperPill(title: String, value: Int, decrement: @escaping () -> Void, increment: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.375)) {
            Text(title)
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
            HStack(spacing: theme.spacing(0.5)) {
                Button(action: decrement) { Image(systemName: "minus") }
                    .buttonStyle(.plain)
                Text(Rating(halfStars: value)?.starString ?? "—")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.primaryText)
                    .frame(minWidth: theme.spacing(5), alignment: .center)
                Button(action: increment) { Image(systemName: "plus") }
                    .buttonStyle(.plain)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(theme.accent)
            .padding(.horizontal, theme.spacing(0.75))
            .padding(.vertical, theme.spacing(0.5))
            .background(
                RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                    .fill(theme.surface)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Genres

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            label("Genre")
            FlowLayout(spacing: theme.spacing(0.5)) {
                ForEach(facets.genres, id: \.value) { facet in
                    Button {
                        model.toggleGenre(facet.value)
                    } label: {
                        Chip(facet.value, selected: model.filter.genres.contains(facet.value))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Decades

    private var decadeSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            label("Decade")
            FlowLayout(spacing: theme.spacing(0.5)) {
                ForEach(facets.decades.map(\.value).sorted(), id: \.self) { decade in
                    Button {
                        model.toggleDecade(decade)
                    } label: {
                        Chip("\(decade)s", selected: model.filter.decades.contains(decade))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Runtime

    private func runtimeSection(bounds: ClosedRange<Int>) -> some View {
        let current = model.filter.runtimeRange ?? bounds
        let upper = Binding<Double>(
            get: { Double(current.upperBound) },
            set: { newValue in
                let hi = max(bounds.lowerBound, min(bounds.upperBound, Int(newValue.rounded())))
                model.setRuntimeRange(bounds.lowerBound...hi)
            }
        )
        return VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            label("Runtime")
            Text("Up to \(current.upperBound) min")
                .font(theme.font(.caption))
                .foregroundStyle(theme.primaryText)
            Slider(
                value: upper,
                in: Double(bounds.lowerBound)...Double(bounds.upperBound)
            )
            .tint(theme.accent)
            if model.filter.runtimeRange != nil {
                clearButton { model.setRuntimeRange(nil) }
            }
        }
    }

    // MARK: Toggles

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            label("Flags")
            triStateRow("Rewatch", value: model.filter.isRewatch) { model.cycleRewatch() }
            triStateRow("Liked", value: model.filter.isLiked) { model.cycleLiked() }
            triStateRow("Has review", value: model.filter.hasReview) { model.cycleReview() }
        }
    }

    private func triStateRow(_ title: String, value: Bool?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.primaryText)
                Spacer()
                Image(systemName: triStateSymbol(value))
                    .foregroundStyle(triStateColor(value))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func triStateSymbol(_ value: Bool?) -> String {
        switch value {
        case .none: return "circle"
        case .some(true): return "checkmark.circle.fill"
        case .some(false): return "minus.circle.fill"
        }
    }

    private func triStateColor(_ value: Bool?) -> Color {
        switch value {
        case .none: return theme.secondaryText
        case .some(true): return theme.accent
        case .some(false): return theme.secondaryAccent
        }
    }

    // MARK: Helpers

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(theme.font(.caption))
            .foregroundStyle(theme.secondaryText)
            .tracking(1.2)
    }

    private func clearButton(_ action: @escaping () -> Void) -> some View {
        Button("Clear", action: action)
            .buttonStyle(.plain)
            .font(theme.font(.caption))
            .foregroundStyle(theme.secondaryAccent)
    }
}
