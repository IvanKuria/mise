import SwiftUI
import UniformTypeIdentifiers
import ThemeKit
import MiseUI
import MiseCore

public extension UTType {
    /// The shareable Mise theme document type, surfaced as `.misetheme`.
    static let miseTheme = UTType(exportedAs: "com.mise.theme", conformingTo: .json)
}

/// The "ricing" surface: a controls panel for customizing a ``Theme`` next to a
/// live preview rendered with real MiseUI components, plus Import/Export of a
/// shareable `.misetheme` document.
public struct ThemeStudioView: View {
    @Bindable private var model: ThemeStudioModel

    @State private var isExporting = false
    @State private var isImporting = false

    public init(model: ThemeStudioModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 0) {
            controls
                .frame(width: 320)
                .background(.background)

            Divider()

            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 560)
        .fileExporter(
            isPresented: $isExporting,
            document: ThemeFileDocument(model: model),
            contentType: .miseTheme,
            defaultFilename: model.theme.name
        ) { _ in }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.miseTheme, .json]
        ) { result in
            handleImport(result)
        }
    }

    // MARK: Controls

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                section("Preset") { presetPicker }
                section("Colors") { colorWells }
                section("Typography") { typographyControls }
                section("Layout") { layoutControls }

                if let error = model.importError {
                    importErrorBanner(error)
                }
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Theme Studio")
                    .font(.headline)
                Text(model.theme.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Import") { isImporting = true }
            Button("Export") { isExporting = true }
        }
    }

    private var presetPicker: some View {
        Picker("Preset", selection: presetSelection) {
            ForEach(model.presets) { preset in
                Text(preset.name).tag(preset.id)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    private var presetSelection: Binding<String> {
        Binding(
            get: { model.theme.id },
            set: { id in
                if let preset = model.presets.first(where: { $0.id == id }) {
                    model.applyPreset(preset)
                }
            }
        )
    }

    private var colorWells: some View {
        VStack(spacing: 8) {
            ForEach(PaletteRole.allCases) { role in
                HStack {
                    ColorPicker(
                        role.label,
                        selection: binding(for: role),
                        supportsOpacity: true
                    )
                    Spacer()
                    Text(model.hex(for: role))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func binding(for role: PaletteRole) -> Binding<Color> {
        Binding(
            get: { model.color(for: role) },
            set: { model.setColor($0, for: role) }
        )
    }

    private var typographyControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Font", selection: fontFamilyBinding) {
                ForEach(FontFamily.allCases, id: \.self) { family in
                    Text(family.rawValue.capitalized).tag(family)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Size")
                    Spacer()
                    Text(String(format: "%.0f%%", model.theme.typography.sizeScale * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: sizeScaleBinding,
                    in: ThemeStudioModel.sizeScaleRange
                )
            }
        }
    }

    private var layoutControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Density", selection: densityBinding) {
                ForEach(LayoutDensity.allCases, id: \.self) { density in
                    Text(density.rawValue.capitalized).tag(density)
                }
            }
            Picker("Poster Wall", selection: wallBinding) {
                ForEach(PosterWallStyle.allCases, id: \.self) { style in
                    Text(style.rawValue.capitalized).tag(style)
                }
            }
            Picker("Widget", selection: widgetBinding) {
                ForEach(WidgetSkin.allCases, id: \.self) { skin in
                    Text(skin.rawValue.capitalized).tag(skin)
                }
            }
        }
        .pickerStyle(.menu)
    }

    private func importErrorBanner(_ error: ThemeDocumentError) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(Self.message(for: error))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Bindings

    private var fontFamilyBinding: Binding<FontFamily> {
        Binding(get: { model.theme.typography.family }, set: { model.setFontFamily($0) })
    }
    private var sizeScaleBinding: Binding<Double> {
        Binding(get: { model.theme.typography.sizeScale }, set: { model.setSizeScale($0) })
    }
    private var densityBinding: Binding<LayoutDensity> {
        Binding(get: { model.theme.layoutDensity }, set: { model.setLayoutDensity($0) })
    }
    private var wallBinding: Binding<PosterWallStyle> {
        Binding(get: { model.theme.posterWallStyle }, set: { model.setPosterWallStyle($0) })
    }
    private var widgetBinding: Binding<WidgetSkin> {
        Binding(get: { model.theme.widgetSkin }, set: { model.setWidgetSkin($0) })
    }

    // MARK: Live preview

    private var preview: some View {
        let mise = MiseTheme(model.theme)
        return ScrollView {
            VStack(alignment: .leading, spacing: mise.spacing(2)) {
                SectionHeader("Your Mise", subtitle: model.theme.name)

                HStack(spacing: mise.spacing(1.5)) {
                    StatCard(title: "Films", value: "1,284", caption: "this year")
                    StatCard(title: "Hours", value: "2,041")
                    StatCard(title: "Avg", value: "★ 3.8")
                }

                VStack(alignment: .leading, spacing: mise.spacing(0.5)) {
                    StarRatingView(rating: Rating(halfStars: 9))
                    StarRatingView(rating: Rating(halfStars: 6))
                }

                SectionHeader("Poster Wall", subtitle: model.theme.posterWallStyle.rawValue)
                PosterWallView(
                    films: MiseUIPreviewData.films,
                    style: model.theme.posterWallStyle
                )
            }
            .padding(mise.spacing(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(mise.background)
        .miseTheme(model.theme)
    }

    // MARK: Helpers

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let needsScope = url.startAccessingSecurityScopedResource()
            defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) {
                model.importData(data)
            } else {
                model.importError = .malformedData
            }
        case .failure:
            // User-cancelled or unreadable; leave any prior state intact.
            break
        }
    }

    /// A user-facing message for an import error.
    static func message(for error: ThemeDocumentError) -> String {
        switch error {
        case .malformedData:
            return "That file isn't a valid Mise theme."
        case .unsupportedSchemaVersion(let version):
            return "This theme was made with a newer version of Mise (format v\(version))."
        }
    }
}

/// A `FileDocument` wrapper so SwiftUI's `.fileExporter` can write the working
/// theme as a `.misetheme` document.
struct ThemeFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.miseTheme, .json]
    static let writableContentTypes: [UTType] = [.miseTheme]

    let data: Data

    @MainActor
    init(model: ThemeStudioModel) {
        self.data = (try? model.exportData()) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    ThemeStudioView(model: ThemeStudioModel(theme: .technicolor))
}
