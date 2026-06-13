import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPG"
    case png = "PNG"

    var id: String { rawValue }

    var contentType: UTType {
        switch self {
        case .jpeg: .jpeg
        case .png: .png
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: "jpg"
        case .png: "png"
        }
    }
}

@MainActor
final class ExportService {
    func chooseExportURL(defaultName: String, format: ExportFormat) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Export Processed Image"
        panel.nameFieldStringValue = "\(defaultName)-filmforge.\(format.fileExtension)"
        panel.allowedContentTypes = [format.contentType]
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    func write(_ image: CGImage, to url: URL, format: ExportFormat, colorSpace: CGColorSpace) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, format.contentType.identifier as CFString, 1, nil) else {
            throw FilmPipelineError.exportFailed
        }

        let profileName = colorSpace.name as String? ?? "sRGB IEC61966-2.1"
        let properties: [CFString: Any]
        switch format {
        case .jpeg:
            properties = [
                kCGImageDestinationLossyCompressionQuality: 0.92,
                kCGImagePropertyProfileName: profileName
            ]
        case .png:
            properties = [
                kCGImagePropertyProfileName: profileName,
                kCGImagePropertyPNGDictionary: [:]
            ]
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw FilmPipelineError.exportFailed
        }
    }
}
