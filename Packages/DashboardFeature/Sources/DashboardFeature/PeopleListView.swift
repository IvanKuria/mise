import SwiftUI
import StatsEngine
import MiseUI

/// A ranked list of people (directors or cast) with film counts and average
/// rating captions.
struct PeopleListView: View {
    @Environment(\.miseTheme) private var theme

    let people: [NamedAggregate]
    let limit: Int

    init(people: [NamedAggregate], limit: Int = 6) {
        self.people = people
        self.limit = limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            ForEach(Array(people.prefix(limit).enumerated()), id: \.element.id) { index, person in
                HStack(alignment: .firstTextBaseline, spacing: theme.spacing()) {
                    Text("\(index + 1)")
                        .font(theme.font(.mono))
                        .foregroundStyle(theme.secondaryAccent)
                        .frame(width: theme.spacing(2.5), alignment: .trailing)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.name)
                            .font(theme.font(.body))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(1)
                        Text(DashboardFormat.aggregateCaption(count: person.count, averageRating: person.averageRating))
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
