# Contributing to mise

Thanks for your interest in mise — a native macOS notch-bar companion for
Letterboxd. Contributions are welcome.

## Project layout

mise is a SwiftUI + AppKit agent app (macOS 14+), built with
[XcodeGen](https://github.com/yonaskolb/XcodeGen). The Xcode project is
**generated** from `App/project.yml` — never edit `Mise.xcodeproj` by hand.

```
App/Sources/            the notch app: window, panels, settings, app state
Packages/
  MiseCore/             value-type domain models (Film, DiaryEntry, …)
  LetterboxdScrape/     public-RSS parsing + polite HTML fallback (SwiftSoup)
  TMDBKit/              optional TMDB client (posters / synopses)
  FilmEnrichment/       TMDB enrichment over MiseCore films
  LocalStore/           SwiftData persistence
  AppCore/              the pipeline integration point (LibraryController)
```

## Build & run

```bash
brew install xcodegen          # once
cd App
xcodegen generate              # regenerate Mise.xcodeproj after any project.yml change
open Mise.xcodeproj            # build & run the "Mise" scheme (⌘R)
```

The app lives in the notch (hover to expand) and adds a menu-bar item. On first
run, enter a **public Letterboxd username**. Posters/synopses are optional and
require a free [TMDB API key](https://www.themoviedb.org/settings/api) entered
in Settings.

Dev hooks (env vars): `MISE_DEMO=1` loads sample data; `MISE_FORCE_OPEN=1`
pins the notch open for screenshots; `MISE_PANEL=recent|onThisDay|heatmap`
selects the initial panel.

## Tests

```bash
cd Packages/LetterboxdScrape && swift test    # RSS/HTML parser + orchestration
```

Please add tests for parser changes (see `Tests/.../RSSParserTests.swift`).

## Guidelines

- Keep the data layer **read-only** over **public** Letterboxd data (RSS first).
  Don't add login/automation that violates Letterboxd's terms.
- Match the existing visual language (Dynamic-Island register: black panel,
  system font, restrained color). Keep the notch compact.
- Swift 6 strict concurrency; prefer value types and `@MainActor` UI.
- Run `swift build`/`swift test` on touched packages and build the app before a PR.

## Releasing

Signing + notarization steps live in [`NOTARIZE.md`](NOTARIZE.md)
(`Scripts/package-dmg.sh` → `Scripts/notarize.sh`).

## Disclaimers

mise is **unofficial — not affiliated with, endorsed by, or sponsored by
Letterboxd.** It uses the TMDB API but is **not endorsed or certified by TMDB.**
