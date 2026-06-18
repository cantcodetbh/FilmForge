import CoreImage
import Foundation

struct SceneAnalysis {
    var meanLuma: Double
    var maxLuma: Double
    var warmth: Double
    var saturation: Double

    static let neutral = SceneAnalysis(meanLuma: 0.45, maxLuma: 0.92, warmth: 0, saturation: 0.25)
}

struct SceneAnalyzer {
    var context: CIContext

    func analyze(_ image: CIImage) -> SceneAnalysis {
        guard image.extent.width > 0, image.extent.height > 0 else { return .neutral }

        let average = sample(filter: "CIAreaAverage", image: image)
        let maximum = sample(filter: "CIAreaMaximum", image: image)
        guard let average, let maximum else { return .neutral }

        let meanLuma = luma(average)
        let maxLuma = luma(maximum)
        let maxChannel = max(average.0, max(average.1, average.2))
        let minChannel = min(average.0, min(average.1, average.2))
        let saturation = maxChannel > 0.001 ? (maxChannel - minChannel) / maxChannel : 0
        let warmth = (average.0 - average.2) / max(meanLuma, 0.08)

        return SceneAnalysis(
            meanLuma: meanLuma,
            maxLuma: maxLuma,
            warmth: warmth,
            saturation: saturation
        )
    }

    private func sample(filter name: String, image: CIImage) -> (Double, Double, Double, Double)? {
        let extent = image.extent
        guard let output = CIFilter(
            name: name,
            parameters: [
                kCIInputImageKey: image,
                kCIInputExtentKey: CIVector(cgRect: extent)
            ]
        )?.outputImage else {
            return nil
        }

        var bitmap = [Float](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: MemoryLayout<Float>.size * 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBAf,
            colorSpace: RenderContext.workingColorSpace
        )
        return (Double(bitmap[0]), Double(bitmap[1]), Double(bitmap[2]), Double(bitmap[3]))
    }

    private func luma(_ sample: (Double, Double, Double, Double)) -> Double {
        sample.0 * 0.2126 + sample.1 * 0.7152 + sample.2 * 0.0722
    }
}
