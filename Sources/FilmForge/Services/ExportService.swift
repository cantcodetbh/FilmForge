import AppKit
import CoreImage
import Foundation
import UniformTypeIdentifiers

struct ExportService {
    var pipeline = FilmPipeline()

    func export(
        imported: ImportedPhoto,
        profile: FilmLookProfile,
        componentIntensities: LookComponentIntensities,
        toggles: PipelineToggles,
        settings: ExportSettings,
        renderSeed: Double
    ) throws -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [settings.format == .jpeg ? .jpeg : .png]
        panel.nameFieldStringValue = imported.url.deletingPathExtension().lastPathComponent + "-\(profile.id)." + settings.format.fileExtension
        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        let rendered = pipeline.render(
            input: imported.image,
            profile: profile,
            componentIntensities: componentIntensities,
            toggles: toggles,
            exportSettings: settings,
            renderSeed: renderSeed
        )

        let context = RenderContext.shared.context
        let colorSpace = settings.outputColorSpaceName == "Display P3"
            ? CGColorSpace(name: CGColorSpace.displayP3)!
            : RenderContext.outputColorSpace

        switch settings.format {
        case .jpeg:
            guard let cgImage = context.createCGImage(rendered, from: rendered.extent, format: .RGBA8, colorSpace: colorSpace) else {
                throw CocoaError(.fileWriteUnknown)
            }
            let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
            guard let destination else { throw CocoaError(.fileWriteUnknown) }
            let metadata: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: settings.jpegQuality,
                kCGImagePropertyOrientation: 1
            ]
            CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        case .png:
            guard let data = context.pngRepresentation(of: rendered, format: .RGBA8, colorSpace: colorSpace, options: [:]) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try data.write(to: url, options: .atomic)
        }

        return url
    }
}
