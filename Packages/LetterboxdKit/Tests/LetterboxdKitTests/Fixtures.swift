import Foundation

/// Fixture JSON mirroring the documented Letterboxd API v0 shapes.
enum Fixtures {
    static let token = Data("""
    {
      "access_token": "abc123token",
      "token_type": "bearer",
      "expires_in": 3600
    }
    """.utf8)

    static let memberSearch = Data("""
    {
      "items": [
        {
          "type": "MemberSearchItem",
          "member": {
            "id": "MEM123",
            "username": "dave",
            "displayName": "Dave Letterboxd",
            "avatar": { "sizes": [
              { "width": 100, "height": 100, "url": "https://a.ltrbxd.com/small.jpg" },
              { "width": 1000, "height": 1000, "url": "https://a.ltrbxd.com/large.jpg" }
            ] }
          }
        }
      ]
    }
    """.utf8)

    static let statistics = Data("""
    {
      "counts": {
        "watches": 2500,
        "diaryEntries": 1800,
        "lists": 12,
        "followers": 340,
        "following": 120
      },
      "ratingsHistogram": [
        { "rating": 0.5, "count": 3 },
        { "rating": 3.0, "count": 200 },
        { "rating": 4.5, "count": 90 },
        { "rating": 5.0, "count": 45 }
      ]
    }
    """.utf8)

    static let film = Data("""
    {
      "id": "2bbs",
      "name": "Parasite",
      "releaseYear": 2019,
      "runTime": 133,
      "genres": [
        { "id": "g1", "name": "Comedy" },
        { "id": "g2", "name": "Thriller" }
      ],
      "contributions": [
        { "type": "Director", "contributors": [ { "id": "c1", "name": "Bong Joon-ho" } ] },
        { "type": "Actor", "contributors": [ { "id": "c2", "name": "Song Kang-ho", "characterName": "Ki-taek" } ] }
      ],
      "countries": [ { "code": "KR", "name": "South Korea" } ],
      "languages": [ { "code": "ko", "name": "Korean" } ],
      "poster": { "sizes": [ { "width": 2000, "height": 3000, "url": "https://a.ltrbxd.com/poster.jpg" } ] },
      "rating": 4.56,
      "links": [
        { "type": "tmdb", "id": "496243", "url": "https://www.themoviedb.org/movie/496243" },
        { "type": "letterboxd", "id": "2bbs", "url": "https://letterboxd.com/film/parasite-2019/" }
      ]
    }
    """.utf8)

    static let logEntries = Data("""
    {
      "items": [
        {
          "id": "LE1",
          "film": {
            "id": "2bbs",
            "name": "Parasite",
            "releaseYear": 2019,
            "links": [ { "type": "tmdb", "id": "496243", "url": "x" } ]
          },
          "diaryDetails": { "diaryDate": "2024-03-15", "rewatch": true },
          "rating": 4.5,
          "like": true,
          "review": { "text": "Still incredible." },
          "tags2": [ { "displayTag": "rewatch", "tag": "rewatch" } ],
          "whenCreated": "2024-03-15T20:30:00Z"
        },
        {
          "id": "LE2",
          "film": { "id": "abc", "name": "No Rating Film" },
          "diaryDetails": { "diaryDate": "2024-02-01", "rewatch": false },
          "like": false
        }
      ],
      "next": "cursor-2"
    }
    """.utf8)

    static let watchlist = Data("""
    {
      "items": [
        { "id": "w1", "name": "Aftersun", "releaseYear": 2022 },
        { "id": "w2", "name": "The Zone of Interest", "releaseYear": 2023 }
      ]
    }
    """.utf8)

    static let lists = Data("""
    {
      "items": [
        {
          "id": "L1",
          "name": "Best of 2019",
          "description": "My favourites",
          "ranked": true,
          "entries": [
            { "film": { "id": "2bbs", "name": "Parasite", "releaseYear": 2019 } },
            { "film": { "id": "xyz", "name": "Marriage Story", "releaseYear": 2019 } }
          ]
        }
      ]
    }
    """.utf8)

    static let filmSearch = Data("""
    {
      "items": [
        { "type": "FilmSearchItem", "film": { "id": "2bbs", "name": "Parasite", "releaseYear": 2019 } },
        { "type": "ContributorSearchItem" }
      ]
    }
    """.utf8)
}
