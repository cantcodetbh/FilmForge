import CoreGraphics
import CoreImage
import Foundation

struct RenderContext {
    let ciContext: CIContext
    let profile: FilmProfile
    let adjustments: UserAdjustments
    let mode: RenderMode
    let sourceColorSpace: CGColorSpace
    let workingColorSpace: CGColorSpace
    let outputColorSpace: CGColorSpace
    let workingFormat: CIFormat
    let renderSeed: UInt32

    var colorSpace: CGColorSpace { outputColorSpace }
}

enum RenderMode {
    case preview(maxLongEdge: CGFloat)
    case export
}

enum FilmPipelineError: LocalizedError {
    case emptyOutput
    case renderFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .emptyOutput:
            "The image pipeline did not produce an output image."
        case .renderFailed:
            "FilmForge could not render the processed image."
        case .exportFailed:
            "FilmForge could not export the processed image."
        }
    }
}
