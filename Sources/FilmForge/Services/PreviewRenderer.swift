import AppKit
import CoreImage
import Foundation

struct PreviewRenderer {
    var pipeline = FilmPipeline()

    func previewImage(
        input: CIImage,
        profile: FilmLookProfile,
        componentIntensities: LookComponentIntensities,
        toggles: PipelineToggles,
        showBefore: Bool,
        renderSeed: Double,
        maxDimension: CGFloat = 1800
    ) -> NSImage? {
        let base = resizeForPreview(input, maxDimension: maxDimension)
        let rendered = showBefore
            ? base
            : pipeline.render(input: base, profile: profile, componentIntensities: componentIntensities, toggles: toggles, renderSeed: renderSeed)
        guard let cgImage = RenderContext.shared.context.createCGImage(rendered, from: rendered.extent, format: .RGBA8, colorSpace: RenderContext.outputColorSpace) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: rendered.extent.width, height: rendered.extent.height))
    }

    private func resizeForPreview(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let longest = max(image.extent.width, image.extent.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
}
