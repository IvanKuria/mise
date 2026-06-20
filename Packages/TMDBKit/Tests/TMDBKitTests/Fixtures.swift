import Foundation

/// Fixture JSON mirroring real TMDB API responses.
enum Fixtures {
    /// Mirrors GET /movie/{id} for "Parasite" (tmdb id 496243), trimmed to fields we decode.
    static let movie = Data("""
    {
      "id": 496243,
      "title": "Parasite",
      "poster_path": "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
      "runtime": 133,
      "release_date": "2019-05-30",
      "genres": [
        { "id": 35, "name": "Comedy" },
        { "id": 53, "name": "Thriller" },
        { "id": 18, "name": "Drama" }
      ]
    }
    """.utf8)

    /// Mirrors GET /movie/{id}/watch/providers with a US region populated.
    static let watchProviders = Data("""
    {
      "id": 496243,
      "results": {
        "US": {
          "link": "https://www.themoviedb.org/movie/496243/watch?locale=US",
          "flatrate": [
            { "logo_path": "/peURlLlr8jggOwK53fJ5wdQl05.jpg", "provider_id": 8, "provider_name": "Netflix", "display_priority": 0 },
            { "logo_path": "/68MNrwlkpF7WnmNPXLah69CR5cb.jpg", "provider_id": 15, "provider_name": "Hulu", "display_priority": 1 }
          ],
          "rent": [
            { "logo_path": "/seGSXajazLMCKGB5hnRCEtVZazp.jpg", "provider_id": 2, "provider_name": "Apple TV", "display_priority": 4 }
          ],
          "buy": [
            { "logo_path": "/9ghgSC0MA082EL6HLCW3GalykFD.jpg", "provider_id": 3, "provider_name": "Google Play Movies", "display_priority": 8 }
          ]
        }
      }
    }
    """.utf8)

    /// Watch providers response where the requested region is absent.
    static let watchProvidersEmpty = Data("""
    {
      "id": 496243,
      "results": {}
    }
    """.utf8)

    /// Mirrors GET /search/movie?query=Parasite with multiple results,
    /// trimmed to fields we decode.
    static let searchMovie = Data("""
    {
      "page": 1,
      "results": [
        {
          "id": 496243,
          "title": "Parasite",
          "poster_path": "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
          "release_date": "2019-05-30",
          "overview": "All unemployed, Ki-taek's family takes peculiar interest..."
        },
        {
          "id": 61225,
          "title": "Parasite",
          "poster_path": "/oldParasite1982.jpg",
          "release_date": "1982-03-12",
          "overview": "A doctor has developed a deadly parasite..."
        },
        {
          "id": 12345,
          "title": "Parasite (no date)",
          "poster_path": null,
          "release_date": "",
          "overview": "No release date here."
        }
      ],
      "total_pages": 1,
      "total_results": 3
    }
    """.utf8)

    /// A /search/movie response with no results.
    static let searchEmpty = Data("""
    {
      "page": 1,
      "results": [],
      "total_pages": 1,
      "total_results": 0
    }
    """.utf8)

    /// A typical TMDB error body for a non-2xx response.
    static let errorBody = Data("""
    {
      "success": false,
      "status_code": 7,
      "status_message": "Invalid API key: You must be granted a valid key."
    }
    """.utf8)
}
