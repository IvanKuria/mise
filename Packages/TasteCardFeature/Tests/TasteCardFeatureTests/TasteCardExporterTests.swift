import Testing
import Foundation
import ThemeKit
import TasteProfile
@testable import TasteCardFeature

@Suite("TasteCardExporter")
struct TasteCardExporterTests {

    private var sampleProfile: TasteProfile {
        TasteProfile(
            archetype: "Auteur Worshipper",
            definingGenres: [
                DefiningGenre(name: "Drama", count: 40, share: 0.4, lift: 2.0, label: "Drama devotee"),
                DefiningGenre(name: "Thriller", count: 20, share: 0.2, lift: 1.5, label: "Thriller"),
            ],
            hottestTakes: [
                HottestTake(filmID: "1", filmName: "Mandy", memberStars: 5, communityStars: 3, delta: 2, direction: .lovedItCrowdDidnt, blurb: "You loved Mandy — the crowd didn't."),
            ],
            obsessions: [
                Obsession(kind: .director, key: "p1", name: "David Lynch", count: 7, label: "7 films"),
            ],
            blindSpots: [],
            headlineStats: [
                HeadlineStat(key: "filmsLogged", label: "Films logged", value: "1,284"),
                HeadlineStat(key: "averageRating", label: "Average rating", value: "3.8★"),
            ]
        )
    }

    /// `ImageRenderer` runs headless on macOS in test runs; this verifies the full
    /// rasterize-and-encode path returns real PNG bytes. If a future toolchain
    /// cannot render headless, this is the single test to quarantine — the string
    /// projection in `TasteCardContentTests` stays valid regardless.
    @MainActor
    @Test("Square export returns non-nil PNG data with a PNG signature")
    func squareExportProducesPNG() throws {
        let exporter = TasteCardExporter()
        let data = exporter.pngData(
            for: sampleProfile,
            theme: .noir,
            size: CGSize(width: 600, height: 600),
            scale: 1.0
        )
        let bytes = try #require(data)
        #expect(bytes.count > 1000)
        // PNG magic number: 89 50 4E 47 0D 0A 1A 0A
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        #expect(Array(bytes.prefix(8)) == signature)
    }

    @MainActor
    @Test("Portrait export returns non-nil PNG data")
    func portraitExportProducesPNG() throws {
        let exporter = TasteCardExporter()
        let data = exporter.pngData(
            for: sampleProfile,
            theme: .technicolor,
            size: CGSize(width: 540, height: 960),
            scale: 1.0
        )
        let bytes = try #require(data)
        #expect(bytes.count > 1000)
    }

    @MainActor
    @Test("Empty profile still exports a card")
    func emptyProfileExports() throws {
        let exporter = TasteCardExporter()
        let data = exporter.pngData(
            for: .empty,
            theme: .criterion,
            size: CGSize(width: 500, height: 500),
            scale: 1.0
        )
        _ = try #require(data)
    }
}
