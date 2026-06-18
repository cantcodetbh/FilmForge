import AppKit
import CoreImage
import Foundation
import UniformTypeIdentifiers

struct ImportedPhoto {
    var url: URL
    var image: CIImage
    var metadata: [String: Any]
    var colorSpace: CGColorSpace?
    var renderSeed: Double
}

struct ImageImportService {
    func openPanel() -> ImportedPhoto? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return try? load(url: url)
    }

    func load(url: URL) throws -> ImportedPhoto {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let metadata = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]) ?? [:]
        let colorSpace = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            .flatMap { ($0 as NSDictionary)[kCGImagePropertyColorModel] as? String }
            .flatMap { _ in CGColorSpace(name: CGColorSpace.sRGB) }

        guard let image = CIImage(contentsOf: url, options: [
            .applyOrientationProperty: true,
            .nearestSampling: false
        ]) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return ImportedPhoto(
            url: url,
            image: image,
            metadata: metadata,
            colorSpace: colorSpace,
            renderSeed: Self.renderSeed(for: url, image: image)
        )
    }

    private static func renderSeed(for url: URL, image: CIImage) -> Double {
        var hash: UInt64 = 1469598103934665603
        let text = "\(url.path)|\(Int(image.extent.width))x\(Int(image.extent.height))"
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return Double(hash % 1_000_000) / 997.0
    }
}
