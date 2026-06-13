import CoreImage
import Foundation

struct LUT3D {
    let dimension: Int
    let data: Data
}

enum CubeLUTParser {
    static func parse(url: URL) throws -> LUT3D {
        let text = try String(contentsOf: url, encoding: .utf8)
        var dimension = 0
        var samples: [Float] = []

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let parts = line.split(separator: " ").map(String.init)

            if parts.first == "LUT_3D_SIZE", let size = parts.dropFirst().first.flatMap(Int.init) {
                dimension = size
                continue
            }

            guard parts.count >= 3,
                  let red = Float(parts[0]),
                  let green = Float(parts[1]),
                  let blue = Float(parts[2])
            else { continue }
            samples.append(contentsOf: [red, green, blue, 1])
        }

        guard dimension > 1, samples.count == dimension * dimension * dimension * 4 else {
            throw FilmPipelineError.renderFailed
        }
        return LUT3D(dimension: dimension, data: Data(bytes: samples, count: samples.count * MemoryLayout<Float>.size))
    }
}

enum GeneratedLUTFactory {
    static func make(profile: FilmProfile, dimension: Int) -> LUT3D {
        let recipe = profile.recipe
        let size = max(8, min(dimension, 64))
        var samples = [Float]()
        samples.reserveCapacity(size * size * size * 4)

        for blueIndex in 0..<size {
            for greenIndex in 0..<size {
                for redIndex in 0..<size {
                    let red = Double(redIndex) / Double(size - 1)
                    let green = Double(greenIndex) / Double(size - 1)
                    let blue = Double(blueIndex) / Double(size - 1)
                    let mapped = map(red: red, green: green, blue: blue, recipe: recipe)
                    samples.append(Float(mapped.red))
                    samples.append(Float(mapped.green))
                    samples.append(Float(mapped.blue))
                    samples.append(1)
                }
            }
        }

        return LUT3D(dimension: size, data: Data(bytes: samples, count: samples.count * MemoryLayout<Float>.size))
    }

    private static func map(red: Double, green: Double, blue: Double, recipe: FilmRecipe) -> (red: Double, green: Double, blue: Double) {
        let color = recipe.color
        var r = red * color.redBias
        var g = green * color.greenBias
        var b = blue * color.blueBias
        let luma = max(0, min(1, r * 0.2126 + g * 0.7152 + b * 0.0722))
        let shadow = pow(1 - luma, 1.8)
        let highlight = pow(luma, 1.7)
        let mid = 1 - abs(luma * 2 - 1)

        r += color.shadowRed * 0.11 * shadow + color.highlightRed * 0.09 * highlight
        g += color.shadowGreen * 0.11 * shadow + color.highlightGreen * 0.09 * highlight
        b += color.shadowBlue * 0.11 * shadow + color.highlightBlue * 0.09 * highlight

        let subtractiveCyan = color.cyanShift * 0.055 * mid
        let subtractiveMagenta = color.magentaShift * 0.055 * mid
        let subtractiveYellow = color.yellowShift * 0.055 * mid
        r -= subtractiveCyan
        g -= subtractiveMagenta
        b -= subtractiveYellow
        r += subtractiveMagenta * 0.18 + subtractiveYellow * 0.1
        g += subtractiveCyan * 0.12 + subtractiveYellow * 0.08
        b += subtractiveCyan * 0.12 + subtractiveMagenta * 0.14

        let shoulder = 1 - exp(-max(r, max(g, b)) * (1.75 + max(0, recipe.bloom.amount) * 0.7))
        let shoulderBlend = max(0, luma - 0.62) / 0.38
        r = r * (1 - shoulderBlend) + min(r, shoulder) * shoulderBlend
        g = g * (1 - shoulderBlend) + min(g, shoulder) * shoulderBlend
        b = b * (1 - shoulderBlend) + min(b, shoulder) * shoulderBlend

        if color.monochrome {
            let mono = r * 0.29 + g * 0.58 + b * 0.13
            r = mono * (1 + color.temperature * 0.06)
            g = mono * (1 + color.tint * 0.035)
            b = mono * (1 - color.temperature * 0.05)
        }

        return (clamped(r, 0, 1), clamped(g, 0, 1), clamped(b, 0, 1))
    }
}
