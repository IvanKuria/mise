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

    /// The resolved, live theme that both the controls chrome and the preview
    /// render with, so edits update the whole surface immediately.
    private var mise: MiseTheme { MiseTheme(model.theme) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: mise.spacing(3)) {
                hero
                controlsCard
                    .frame(maxWidth: .infinity, alignment: .leading)
                previewCard
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(mise.spacing(4))
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.clear)
        .miseTheme(model.theme)
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

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: mise.spacing(0.75)) {
            Text("MAKE IT YOURS")
                .font(mise.font(.caption))
                .tracking(2.5)
                .foregroundStyle(mise.accent)
                .lineLimit(1)
            Text("Theme")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(mise.textPrimary)
                .lineLimit(1)
        }
        .padding(.bottom, mise.spacing(0.5))
    }

    // MARK: Controls card

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: mise.spacing(2.5)) {
            controlsHeader

            controlGroup("Preset") { presetPicker }
            controlGroup("Colors") { colorWells }
            controlGroup("Typography") { typographyControls }
            controlGroup("Layout") { layoutControls }

            if let error = model.importError {
                importErrorBanner(error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(mise.spacing(2.5))
        .miseCard(mise)
    }

    private var controlsHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: mise.spacing(1)) {
            VStack(alignment: .leading, spacing: mise.spacing(0.25)) {
                Text(model.theme.name)
                    .font(mise.font(.headline))
                    .foregroundStyle(mise.textPrimary)
                    .lineLimit(1)
                Text("Editing")
                    .font(mise.font(.caption))
                    .tracking(1.2)
                    .foregroundStyle(mise.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: mise.spacing(1)) {
                Button("Import") { isImporting = true }
                    .buttonStyle(.plain)
                    .font(mise.font(.body))
                    .foregroundStyle(mise.textPrimary)
                    .padding(.horizontal, mise.spacing(1.5))
                    .padding(.vertical, mise.spacing(0.875))
                    .miseField(mise)

                Button("Export") { isExporting = true }
                    .buttonStyle(.plain)
                    .font(mise.font(.body))
                    .foregroundStyle(mise.onSelection)
                    .padding(.horizontal, mise.spacing(1.5))
                    .padding(.vertical, mise.spacing(0.875))
                    .background(
                        RoundedRectangle(cornerRadius: mise.smallCornerRadius, style: .continuous)
                            .fill(mise.accent)
                    )
            }
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
        VStack(spacing: mise.spacing(0.75)) {
            ForEach(PaletteRole.allCases) { role in
                HStack(spacing: mise.spacing(1)) {
                    ColorPicker(
                        role.label,
                        selection: binding(for: role),
                        supportsOpacity: true
                    )
                    .font(mise.font(.body))
                    .foregroundStyle(mise.textPrimary)
                    Spacer(minLength: mise.spacing(1))
                    Text(model.hex(for: role))
                        .font(mise.font(.mono))
                        .foregroundStyle(mise.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, mise.spacing(1.25))
                .padding(.vertical, mise.spacing(0.875))
                .miseField(mise)
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
        VStack(alignment: .leading, spacing: mise.spacing(1.5)) {
            Picker("Font", selection: fontFamilyBinding) {
                ForEach(FontFamily.allCases, id: \.self) { family in
                    Text(family.rawValue.capitalized).tag(family)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            VStack(alignment: .leading, spacing: mise.spacing(0.75)) {
                HStack {
                    Text("Size")
                        .font(mise.font(.body))
                        .foregroundStyle(mise.textSecondary)
                    Spacer(minLength: 0)
                    Text(String(format: "%.0f%%", model.theme.typography.sizeScale * 100))
                        .font(mise.font(.mono))
                        .foregroundStyle(mise.textSecondary)
                        .lineLimit(1)
                }
                Slider(
                    value: sizeScaleBinding,
                    in: ThemeStudioModel.sizeScaleRange
                )
                .tint(mise.accent)
            }
        }
    }

    private var layoutControls: some View {
        VStack(alignment: .leading, spacing: mise.spacing(1.5)) {
            labeledPicker("Density") {
                Picker("Density", selection: densityBinding) {
                    ForEach(LayoutDensity.allCases, id: \.self) { density in
                        Text(density.rawValue.capitalized).tag(density)
                    }
                }
            }
            labeledPicker("Poster Wall") {
                Picker("Poster Wall", selection: wallBinding) {
                    ForEach(PosterWallStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
            }
            labeledPicker("Widget") {
                Picker("Widget", selection: widgetBinding) {
                    ForEach(WidgetSkin.allCases, id: \.self) { skin in
                        Text(skin.rawValue.capitalized).tag(skin)
                    }
                }
            }
        }
    }

    /// A label + menu picker row, with the picker styled as a recessed field.
    @ViewBuilder
    private func labeledPicker<P: View>(
        _ label: String,
        @ViewBuilder picker: () -> P
    ) -> some View {
        HStack(spacing: mise.spacing(1)) {
            Text(label)
                .font(mise.font(.body))
                .foregroundStyle(mise.textSecondary)
                .lineLimit(1)
            Spacer(minLength: mise.spacing(1))
            picker()
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(mise.textPrimary)
        }
    }

    private func importErrorBanner(_ error: ThemeDocumentError) -> some View {
        HStack(alignment: .top, spacing: mise.spacing(1)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(mise.secondaryAccent)
            Text(Self.message(for: error))
                .font(mise.font(.caption))
                .foregroundStyle(mise.textSecondary)
        }
        .padding(mise.spacing(1.25))
        .frame(maxWidth: .infinity, alignment: .leading)
        .miseField(mise)
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

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: mise.spacing(2.5)) {
            SectionHeader("Live preview", subtitle: model.theme.name)

            StatBand([
                StatItem(value: "1,284", label: "Films logged"),
                StatItem(value: "2,041", unit: "hrs", label: "Runtime"),
                StatItem(value: "★ 3.8", label: "Avg rating", emphasis: true),
            ])

            VStack(alignment: .leading, spacing: mise.spacing(1.5)) {
                SectionHeader("Ratings", subtitle: "How stars render")
                VStack(alignment: .leading, spacing: mise.spacing(0.5)) {
                    StarRatingView(rating: Rating(halfStars: 9))
                    StarRatingView(rating: Rating(halfStars: 6))
                }
            }

            VStack(alignment: .leading, spacing: mise.spacing(1.5)) {
                SectionHeader("Poster wall", subtitle: model.theme.posterWallStyle.rawValue.capitalized)
                PosterWallView(
                    films: MiseUIPreviewData.films,
                    style: model.theme.posterWallStyle
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(mise.spacing(2.5))
        .miseCard(mise)
    }

    // MARK: Helpers

    /// A controls subgroup: a `SectionHeader` over its content.
    @ViewBuilder
    private func controlGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: mise.spacing(1.25)) {
            SectionHeader(title)
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
