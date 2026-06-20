import Foundation
import LetterboxdKit
import MiseCore

// API spike CLI. Reads LETTERBOXD_API_KEY / LETTERBOXD_API_SECRET from the
// environment, builds a real client, and given a username fetches the member,
// their statistics, and recent log entries, printing a short summary.
//
// It cannot run without a live key — that is expected; it must compile.

@main
struct MiseSmoke {
    static func main() async {
        let env = ProcessInfo.processInfo.environment

        guard let apiKey = env["LETTERBOXD_API_KEY"], !apiKey.isEmpty,
              let apiSecret = env["LETTERBOXD_API_SECRET"], !apiSecret.isEmpty
        else {
            FileHandle.standardError.write(Data(
                "error: set LETTERBOXD_API_KEY and LETTERBOXD_API_SECRET in the environment\n".utf8
            ))
            exit(2)
        }

        let args = CommandLine.arguments
        guard args.count >= 2 else {
            FileHandle.standardError.write(Data("usage: mise-smoke <username>\n".utf8))
            exit(2)
        }
        let username = args[1]

        let config = LetterboxdConfiguration(apiKey: apiKey, apiSecret: apiSecret)
        let client = LetterboxdClient(configuration: config)

        do {
            let member = try await client.member(username: username)
            print("Member: \(member.displayName) (@\(member.username)) id=\(member.id)")

            let stats = try await client.statistics(memberID: member.id)
            print("Watched: \(stats.watchedFilmCount)  Diary: \(stats.diaryEntryCount)  Lists: \(stats.listCount)")
            print("Followers: \(stats.followerCount)  Following: \(stats.followingCount)")
            if !stats.ratingsHistogram.isEmpty {
                let sorted = stats.ratingsHistogram.sorted { $0.key < $1.key }
                let summary = sorted.map { "\(Double($0.key) / 2)★:\($0.value)" }.joined(separator: " ")
                print("Ratings: \(summary)")
            }

            let entries = try await client.logEntries(memberID: member.id, perPage: 10)
            print("\nRecent log entries (\(entries.count)):")
            for entry in entries {
                let year = entry.film.releaseYear.map { " (\($0))" } ?? ""
                let rating = entry.rating?.starString ?? "—"
                let when = entry.watchedDate.map { ISO8601DateFormatter().string(from: $0) } ?? "?"
                print("  \(entry.film.name)\(year)  \(rating)  watched \(when)")
            }
        } catch {
            FileHandle.standardError.write(Data("request failed: \(error)\n".utf8))
            exit(1)
        }
    }
}
