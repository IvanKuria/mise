import Foundation
import MiseCore

/// An actor-based, read-only (v1) client for the Letterboxd API.
///
/// Fetches public data and maps it into MiseCore types. The client owns request
/// signing, OAuth2 client-credentials token caching/refresh, and 429/5xx retry
/// with exponential backoff. All network I/O goes through an injectable
/// `LetterboxdTransport`, so the client can be exercised in tests with no network.
public actor LetterboxdClient {
    private let configuration: LetterboxdConfiguration
    private let transport: LetterboxdTransport
    private let builder: LetterboxdRequestBuilder
    private let maxRetries: Int
    private let now: @Sendable () -> Date

    /// Cached OAuth token; refreshed on expiry.
    private var cachedToken: CachedToken?

    public init(
        configuration: LetterboxdConfiguration,
        transport: LetterboxdTransport = URLSessionLetterboxdTransport(),
        credentials: RequestCredentialsProvider = LiveRequestCredentialsProvider(),
        maxRetries: Int = 3,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.configuration = configuration
        self.transport = transport
        self.builder = LetterboxdRequestBuilder(configuration: configuration, credentials: credentials)
        self.maxRetries = maxRetries
        self.now = now
    }

    // MARK: - Public endpoints

    /// Resolve a handle to a member summary. Tries `/search` filtered to members.
    public func member(username: String) async throws -> MemberSummary {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "input", value: username),
            URLQueryItem(name: "include", value: "MemberSearchItem"),
            URLQueryItem(name: "perPage", value: "20"),
        ]
        let response: MemberSearchResponseDTO = try await get(path: "search", queryItems: items)
        let members = (response.items ?? []).compactMap { $0.member }
        // Prefer an exact (case-insensitive) username match, else the first.
        let match = members.first { $0.username?.lowercased() == username.lowercased() }
            ?? members.first
        guard let dto = match, let mapped = LetterboxdMappers.member(dto) else {
            throw LetterboxdError.memberNotFound(username)
        }
        return mapped
    }

    /// Aggregate counts and ratings histogram for a member.
    public func statistics(memberID: String) async throws -> MemberStatistics {
        let dto: MemberStatisticsDTO = try await get(path: "member/\(memberID)/statistics")
        return LetterboxdMappers.statistics(dto)
    }

    /// Diary / log entries for a member (newest first by default).
    public func logEntries(
        memberID: String,
        perPage: Int = 50,
        cursor: String? = nil
    ) async throws -> [DiaryEntry] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "member", value: memberID),
            URLQueryItem(name: "perPage", value: String(perPage)),
        ]
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        let response: LogEntriesResponseDTO = try await get(path: "log-entries", queryItems: items)
        return (response.items ?? []).compactMap(LetterboxdMappers.diaryEntry)
    }

    /// A member's watchlist.
    public func watchlist(memberID: String) async throws -> [WatchlistItem] {
        let response: WatchlistResponseDTO = try await get(path: "member/\(memberID)/watchlist")
        return (response.items ?? []).compactMap(LetterboxdMappers.watchlistItem)
    }

    /// A member's lists.
    public func lists(memberID: String) async throws -> [FilmList] {
        let items = [URLQueryItem(name: "member", value: memberID)]
        let response: ListsResponseDTO = try await get(path: "lists", queryItems: items)
        return (response.items ?? []).compactMap(LetterboxdMappers.filmList)
    }

    /// A single film by Letterboxd id.
    public func film(id: String) async throws -> Film {
        let dto: FilmDTO = try await get(path: "film/\(id)")
        guard let mapped = LetterboxdMappers.film(dto) else {
            throw LetterboxdError.decoding("Film \(id) had no usable id")
        }
        return mapped
    }

    /// Search films by free-text query.
    public func search(query: String) async throws -> [Film] {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "include", value: "FilmSearchItem"),
            URLQueryItem(name: "perPage", value: "20"),
        ]
        let response: FilmSearchResponseDTO = try await get(path: "search", queryItems: items)
        return (response.items ?? []).compactMap { $0.film.flatMap(LetterboxdMappers.film) }
    }

    // MARK: - Authentication

    /// Returns a valid bearer token, fetching/refreshing as needed.
    private func accessToken() async throws -> String {
        if let cached = cachedToken, cached.isValid(now: now()) {
            return cached.value
        }
        let request = try builder.makeRequest(
            method: "POST",
            path: TokenRequest.path,
            body: TokenRequest.formBody,
            contentType: TokenRequest.contentType
        )
        let data = try await sendWithRetry(request)
        let dto: TokenResponseDTO
        do {
            dto = try JSONDecoder().decode(TokenResponseDTO.self, from: data)
        } catch {
            throw LetterboxdError.authenticationFailed("Could not decode token response: \(error)")
        }
        guard !dto.accessToken.isEmpty else {
            throw LetterboxdError.authenticationFailed("Empty access token")
        }
        let ttl = TimeInterval(dto.expiresIn ?? 3600)
        cachedToken = CachedToken(value: dto.accessToken, expiresAt: now().addingTimeInterval(ttl))
        return dto.accessToken
    }

    // MARK: - Request plumbing

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let token = try await accessToken()
        var request = try builder.makeRequest(method: "GET", path: path, queryItems: queryItems)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await sendWithRetry(request)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LetterboxdError.decoding("Failed to decode \(T.self): \(error)")
        }
    }

    /// Send a request, retrying transient failures (429 / 5xx) with exponential
    /// backoff. Returns the body on a 2xx; throws on terminal errors.
    private func sendWithRetry(_ request: URLRequest) async throws -> Data {
        var lastStatus = 0
        for attempt in 0...maxRetries {
            let (data, response) = try await transport.data(for: request)
            let code = response.statusCode
            switch code {
            case 200...299:
                return data
            case 429, 500...599:
                lastStatus = code
                if attempt == maxRetries { break }
                let delay = backoffDelay(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            default:
                throw LetterboxdError.httpStatus(code: code, body: data)
            }
        }
        throw LetterboxdError.retriesExhausted(lastStatus: lastStatus)
    }

    /// Exponential backoff: 0.5s, 1s, 2s, ...
    private func backoffDelay(attempt: Int) -> Double {
        0.5 * pow(2.0, Double(attempt))
    }
}

// MARK: - Write endpoints (out of scope for v1)
//
// Write operations (logging films, editing diary entries, managing lists/watchlist)
// are intentionally NOT implemented in v1. They would live in this extension and
// require user-scoped OAuth (authorization-code grant) rather than the
// client-credentials flow used here.
public extension LetterboxdClient {
    // TODO: v2 — write endpoints.
}
