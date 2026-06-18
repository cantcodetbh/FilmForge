import CoreImage
import Foundation
import simd

struct CubeLUTParser {
    enum ParserError: Error {
        case missingSize
        case invalidData
    }

    func parse(url: URL) throws -> LUTCube {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var dimension: Int?
        var domainMin = SIMD3<Float>(0, 0, 0)
        var domainMax = SIMD3<Float>(1, 1, 1)
        var samples: [SIMD3<Float>] = []

        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard let keyword = parts.first else { continue }

            switch keyword.uppercased() {
            case "LUT_3D_SIZE":
                dimension = parts.dropFirst().compactMap(Int.init).first
            case "DOMAIN_MIN":
                let values = parts.dropFirst().compactMap(Float.init)
                if values.count == 3 { domainMin = SIMD3(values[0], values[1], values[2]) }
            case "DOMAIN_MAX":
                let values = parts.dropFirst().compactMap(Float.init)
                if values.count == 3 { domainMax = SIMD3(values[0], values[1], values[2]) }
            case "TITLE", "LUT_1D_SIZE":
                continue
            default:
                let values = parts.compactMap(Float.init)
                if values.count >= 3 {
                    samples.append(SIMD3(values[0], values[1], values[2]))
                }
            }
        }

        guard let dimension else { throw ParserError.missingSize }
        guard samples.count >= dimension * dimension * dimension else { throw ParserError.invalidData }

        var floats = [Float]()
        floats.reserveCapacity(dimension * dimension * dimension * 4)
        let range = simd_max(domainMax - domainMin, SIMD3<Float>(repeating: 0.0001))

        for sample in samples.prefix(dimension * dimension * dimension) {
            let normalized = (sample - domainMin) / range
            floats.append(min(max(normalized.x, 0), 1))
            floats.append(min(max(normalized.y, 0), 1))
            floats.append(min(max(normalized.z, 0), 1))
            floats.append(1)
        }

        return LUTCube(
            dimension: dimension,
            data: Data(bytes: floats, count: floats.count * MemoryLayout<Float>.size),
            colorSpace: RenderContext.outputColorSpace
        )
    }
}
