import AppKit
import CoreGraphics
import CoreImage
import Foundation

actor RenderWorker {
    private let renderer = PreviewRenderer()
    private var previewCache: [PreviewCacheKey: NSImage] = [:]

    private struct PreviewCacheKey: Hashable {
        let sourceID: String
        let profileID: String
        let adjustments: UserAdjustments
        let maxLongEdge: Int
    }

    func renderPreview(
        image: ImportedImage,
        profile: FilmProfile,
        adjustments: UserAdjustments,
        maxLongEdge: CGFloat = 1800
    ) throws -> NSImage {
        let key = PreviewCacheKey(
            sourceID: image.cacheIdentifier,
            profileID: profile.id,
            adjustments: adjustments,
            maxLongEdge: Int(maxLongEdge.rounded())
        )
        if let cached = previewCache[key] {
            return cached
        }
        let rendered = try renderer.renderPreview(
            image: image,
            profile: profile,
            adjustments: adjustments,
            maxLongEdge: maxLongEdge
        )
        previewCache[key] = rendered
        if previewCache.count > 36 {
            previewCache.removeValue(forKey: previewCache.keys.first!)
        }
        return rendered
    }

    func renderPreview(
        source: CIImage,
        profile: FilmProfile,
        adjustments: UserAdjustments,
        maxLongEdge: CGFloat = 1800
    ) throws -> NSImage {
        try renderer.renderPreview(
            source: source,
            profile: profile,
            adjustments: adjustments,
            maxLongEdge: maxLongEdge
        )
    }

    func renderExport(
        image: ImportedImage,
        profile: FilmProfile,
        adjustments: UserAdjustments
    ) throws -> CGImage {
        try renderer.renderExport(
            image: image,
            profile: profile,
            adjustments: adjustments
        )
    }

    func renderExport(
        source: CIImage,
        profile: FilmProfile,
        adjustments: UserAdjustments
    ) throws -> CGImage {
        try renderer.renderExport(
            source: source,
            profile: profile,
            adjustments: adjustments
        )
    }
}
