import AppKit
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class ImageImportService {
    func openImageWithPanel() async throws -> ImportedImage? {
        let panel = NSOpenPanel()
        panel.title = "Import Photo"
        panel.message = "Choose a JPG, PNG, HEIC, or TIFF image to process in FilmForge."
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        return try loadImage(from: url)
    }

    func loadImage(from url: URL) throws -> ImportedImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]) ?? [:]
        let profileName = properties[kCGImagePropertyProfileName as String] as? String
        let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [
            kCGImageSourceShouldCache: false
        ] as CFDictionary)

        let fallbackColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let sourceColorSpace = cgImage?.colorSpace ?? fallbackColorSpace
        let workingColorSpace = CGColorSpace(name: CGColorSpace.extendedSRGB) ?? fallbackColorSpace
        let outputColorSpace = displayOutputColorSpace(sourceColorSpace: sourceColorSpace, fallback: fallbackColorSpace)
        let options: [CIImageOption: Any] = [
            .applyOrientationProperty: true,
            .colorSpace: sourceColorSpace
        ]

        guard let image = CIImage(contentsOf: url, options: options) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let extent = image.extent.integral
        return ImportedImage(
            url: url,
            ciImage: image,
            displayName: url.deletingPathExtension().lastPathComponent,
            pixelSize: CGSize(width: extent.width, height: extent.height),
            sourceColorSpace: sourceColorSpace,
            workingColorSpace: workingColorSpace,
            outputColorSpace: outputColorSpace,
            profileName: profileName ?? sourceColorSpace.name as String? ?? "Embedded/unknown",
            metadata: properties
        )
    }

    private func displayOutputColorSpace(sourceColorSpace: CGColorSpace, fallback: CGColorSpace) -> CGColorSpace {
        if sourceColorSpace.name == CGColorSpace.displayP3 {
            return CGColorSpace(name: CGColorSpace.displayP3) ?? fallback
        }
        return fallback
    }
}
