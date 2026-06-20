# Mise

An open-source, native macOS companion for [Letterboxd](https://letterboxd.com) — a
film-stats studio and power-browser for your watch history. **Unofficial and not
affiliated with Letterboxd.**

> Working name from *mise-en-scène*. Free and open source.

## What it is (and isn't)

Mise is **not** a webview wrapper. It's the insight, utility, and personalization
layer Letterboxd hides, gates behind Pro, or only surfaces once a year:

- **Deep stats + watching heatmap** — ratings curve, contrarian score, genres/decades/people over time, runtime totals, streaks.
- **Power filter/search** — fast, offline, faceted querying over your full history.
- **Compare members** — diff your taste vs a friend; surface what they loved that you haven't seen.
- **Watchlist intelligence** — streaming availability + a "Tonight's Pick" solver (in-app, widget, menu bar).
- **Taste DNA card** — a shareable portrait of your film identity.
- **Deep theming** — customize and share your look ("rice your Letterboxd").

v1 is **public-data only** (read-only) — no login required; you enter a public
Letterboxd handle. Logging/rating/reviewing (write features) arrive once member
OAuth approval lands.

## Repository layout

```
Packages/
  MiseCore/          Pure domain model value types — the shared contract
  LetterboxdKit/     Signed Letterboxd API client + models + `mise-smoke` CLI
  TMDBKit/           TMDB client (posters, metadata, streaming providers)
  StatsEngine/       Pure analytics over a WatchHistory
  RecommenderEngine/ Pure taste-similarity + recommendations
  ThemeKit/          Theming system + shareable presets
  LocalStore/        SwiftData cache + sync engine
App/                 The SwiftUI macOS app, widgets, menu bar (added later)
```

## Status

Early development. See the build plan for architecture and the API-access spike
that gates the public-data approach.
