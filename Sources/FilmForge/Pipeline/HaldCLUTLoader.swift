import AppKit
import CoreImage
import Foundation

struct HaldCLUTLoader {
    enum HaldError: Error {
        case unreadable
        case unsupportedGeometry
        case renderFailed
    }

    func load(url: URL) throws -> LUTCube {
        guard let image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            throw HaldError.unreadable
        }

        let width = Int(image.extent.width.rounded())
        let height = Int(image.extent.height.rounded())
        guard width == height else { throw HaldError.unsupportedGeometry }

        let level = Int(round(pow(Double(width), 1.0 / 3.0)))
        let dimension = level * level
        guard dimension > 1, level * level * level == width else {
            throw HaldError.unsupportedGeometry
        }

        let context = RenderContext.shared.context
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw HaldError.renderFailed
        }

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            throw HaldError.renderFailed
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        var floats = [Float](repeating: 0, count: dimension * dimension * dimension * 4)

        for b in 0..<dimension {
            for g in 0..<dimension {
                for r in 0..<dimension {
                    let index = r + g * dimension + b * dimension * dimension
                    let x = index % width
                    let y = index / width
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    let out = index * 4
                    floats[out + 0] = Float(bytes[offset + 0]) / 255
                    floats[out + 1] = Float(bytes[offset + 1]) / 255
                    floats[out + 2] = Float(bytes[offset + 2]) / 255
                    floats[out + 3] = 1
                }
            }
        }

        return LUTCube(
            dimension: dimension,
            data: Data(bytes: floats, count: floats.count * MemoryLayout<Float>.size),
            colorSpace: RenderContext.outputColorSpace
        )
    }
}
