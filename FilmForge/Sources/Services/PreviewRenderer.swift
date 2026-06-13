import AppKit
import CoreGraphics
import CoreImage
import Foundation

final class PreviewRenderer {
    private let pipeline = ImagePipeline()
    private let colorSpace = CGColorSpace(name: CGColorSpace.extendedSRGB) ?? CGColorSpaceCreateDeviceRGB()
    private lazy var ciContext = CIContext(options: [
        .workingColorSpace: colorSpace,
        .workingFormat: CIFormat.RGBAh,
        .cacheIntermediates: true
    ])

    func renderPreview(
        image: ImportedImage,
        profile: FilmProfile,
        adjustments: UserAdjustments,
        maxLongEdge: CGFloat = 1800
    ) throws -> NSImage {
        try renderPreview(
            source: image.ciImage,
            sourceColorSpace: image.sourceColorSpace,
            workingColorSpace: image.workingColorSpace,
            outputColorSpace: image.outputColorSpace,
            profile: profile,
            adjustments: adjustments,
            maxLongEdge: maxLongEdge
        )
    }

    func renderPreview(
        source: CIImage,
        profile: FilmProfile,
        adjustments: UserAdjustments,
        maxLongEdge: CGFloat = 1800
    ) throws -> NSImage {
        try renderPreview(
            source: source,
            sourceColorSpace: colorSpace,
            workingColorSpace: colorSpace,
            outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) ?? colorSpace,
            profile: profile,
            adjustments: adjustments,
            maxLongEdge: maxLongEdge
        )
    }

    private func renderPreview(
        source: CIImage,
        sourceColorSpace: CGColorSpace,
        workingColorSpace: CGColorSpace,
        outputColorSpace: CGColorSpace,
        profile: FilmProfile,
        adjustments: UserAdjustments,
        maxLongEdge: CGFloat
    ) throws -> NSImage {
        let context = RenderContext(
            ciContext: ciContext,
            profile: profile,
            adjustments: adjustments,
            mode: .preview(maxLongEdge: maxLongEdge),
            sourceColorSpace: sourceColorSpace,
            workingColorSpace: workingColorSpace,
            outputColorSpace: outputColorSpace,
            workingFormat: .RGBAh,
            renderSeed: stableSeed(profileID: profile.id, adjustments: adjustments)
        )
        let output = try pipeline.render(source, context: context)
        guard let cgImage = ciContext.createCGImage(output, from: output.extent, format: .RGBA8, colorSpace: outputColorSpace) else {
            throw FilmPipelineError.renderFailed
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: output.extent.width, height: output.extent.height))
    }

    func renderExport(
        image: ImportedImage,
        profile: FilmProfile,
        adjustments: UserAdjustments
    ) throws -> CGImage {
        try renderExport(
            source: image.ciImage,
            sourceColorSpace: image.sourceColorSpace,
            workingColorSpace: image.workingColorSpace,
            outputColorSpace: image.outputColorSpace,
            profile: profile,
            adjustments: adjustments
        )
    }

    func renderExport(
        source: CIImage,
        profile: FilmProfile,
        adjustments: UserAdjustments
    ) throws -> CGImage {
        try renderExport(
            source: source,
            sourceColorSpace: colorSpace,
            workingColorSpace: colorSpace,
            outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) ?? colorSpace,
            profile: profile,
            adjustments: adjustments
        )
    }

    private func renderExport(
        source: CIImage,
        sourceColorSpace: CGColorSpace,
        workingColorSpace: CGColorSpace,
        outputColorSpace: CGColorSpace,
        profile: FilmProfile,
        adjustments: UserAdjustments
    ) throws -> CGImage {
        let context = RenderContext(
            ciContext: ciContext,
            profile: profile,
            adjustments: adjustments,
            mode: .export,
            sourceColorSpace: sourceColorSpace,
            workingColorSpace: workingColorSpace,
            outputColorSpace: outputColorSpace,
            workingFormat: .RGBAh,
            renderSeed: UInt32.random(in: UInt32.min...UInt32.max)
        )
        let output = try pipeline.render(source, context: context)
        guard let cgImage = ciContext.createCGImage(output, from: output.extent, format: .RGBA8, colorSpace: outputColorSpace) else {
            throw FilmPipelineError.renderFailed
        }
        return cgImage
    }

    private func stableSeed(profileID: String, adjustments: UserAdjustments) -> UInt32 {
        var hasher = Hasher()
        hasher.combine(profileID)
        hasher.combine(adjustments)
        return UInt32(truncatingIfNeeded: hasher.finalize())
    }
}
