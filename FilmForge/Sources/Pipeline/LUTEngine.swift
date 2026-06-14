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

enum GeneratedLookLUTFactory {
    static func make(profile: FilmProfile, dimension: Int) -> LUT3D {
        let recipe = profile.recipe
        let size = max(16, min(dimension, 48))
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
        var r = red
        var g = green
        var b = blue

        let capture = recipe.capture
        if capture.sourceMode != .neutral {
            let clip = capture.sensorClip
            let range = max(0.45, capture.dynamicRange)
            r = captureMap(r, range: range, clip: clip)
            g = captureMap(g, range: range, clip: clip)
            b = captureMap(b, range: range, clip: clip)
        }

        let luma = clamped(r * 0.2126 + g * 0.7152 + b * 0.0722, 0, 1)
        if recipe.filmResponse.enabled {
            let state = interpolatedState(for: luma, response: recipe.filmResponse)
            let contrast = 1 + (state.contrast - 1) * recipe.filmResponse.lumaStrength
            let saturation = 1 + (state.saturation - 1) * recipe.filmResponse.chromaStrength
            r = (r - 0.5) * contrast + 0.5 + state.shadowLift * pow(1 - luma, 1.8)
            g = (g - 0.5) * contrast + 0.5 + state.shadowLift * pow(1 - luma, 1.8)
            b = (b - 0.5) * contrast + 0.5 + state.shadowLift * pow(1 - luma, 1.8)
            let postLuma = clamped(r * 0.2126 + g * 0.7152 + b * 0.0722, 0, 1)
            r = postLuma + (r - postLuma) * saturation
            g = postLuma + (g - postLuma) * saturation
            b = postLuma + (b - postLuma) * saturation
            r *= state.red
            g *= state.green
            b *= state.blue

            let shoulder = state.highlightCompression
            if shoulder > 0.001 {
                let highlight = smoothstep(0.58, 1, postLuma)
                r = mixValue(r, 1 - exp(-r * (1.2 + shoulder * 2.4)), highlight * shoulder)
                g = mixValue(g, 1 - exp(-g * (1.2 + shoulder * 2.4)), highlight * shoulder)
                b = mixValue(b, 1 - exp(-b * (1.2 + shoulder * 2.4)), highlight * shoulder)
            }

            let density = state.density * recipe.filmResponse.densityStrength
            if density > 0.001 {
                let denseSat = 1 + density * 0.72
                let denseLuma = clamped(r * 0.2126 + g * 0.7152 + b * 0.0722, 0, 1)
                r = denseLuma + (r - denseLuma) * denseSat - density * 0.018
                g = denseLuma + (g - denseLuma) * denseSat - density * 0.012
                b = denseLuma + (b - denseLuma) * denseSat - density * 0.006
            }
        }

        let print = recipe.print
        if print.medium != .none {
            let luma = clamped(r * 0.2126 + g * 0.7152 + b * 0.0722, 0, 1)
            r = (r - 0.5) * print.contrast + 0.5
            g = (g - 0.5) * print.contrast + 0.5
            b = (b - 0.5) * print.contrast + 0.5

            let postLuma = clamped(r * 0.2126 + g * 0.7152 + b * 0.0722, 0, 1)
            r = postLuma + (r - postLuma) * print.saturation
            g = postLuma + (g - postLuma) * print.saturation
            b = postLuma + (b - postLuma) * print.saturation

            r -= print.cyan * 0.08
            g -= print.magenta * 0.08
            b -= print.yellow * 0.08
            r += print.magenta * 0.02 + print.yellow * 0.035
            g += print.cyan * 0.02 + print.yellow * 0.02
            b += print.cyan * 0.025 + print.magenta * 0.03

            let highlight = smoothstep(0.62, 1, luma)
            r += print.highlightWarmth * 0.07 * highlight
            g += print.highlightWarmth * 0.025 * highlight
            b -= print.highlightWarmth * 0.04 * highlight

            r = remapBlackWhite(r, black: print.blackPoint, white: print.whitePoint)
            g = remapBlackWhite(g, black: print.blackPoint, white: print.whitePoint)
            b = remapBlackWhite(b, black: print.blackPoint, white: print.whitePoint)

            if print.paperTint > 0.001 {
                r += print.paperTint * 0.025
                g += print.paperTint * 0.018
                b -= print.paperTint * 0.018
            }
        }

        return (clamped(r, 0, 1), clamped(g, 0, 1), clamped(b, 0, 1))
    }

    private static func captureMap(_ value: Double, range: Double, clip: Double) -> Double {
        let normalized = pow(clamped(value, 0, 1), 1 / range)
        guard clip > 0 else { return normalized }
        let clipped = 1 - exp(-normalized * (1.2 + clip * 3.2))
        return mixValue(normalized, clipped, min(0.85, clip))
    }

    private static func interpolatedState(
        for luma: Double,
        response: FilmResponseRecipe
    ) -> FilmResponseRecipe.ExposureState {
        if luma < 0.5 {
            return blend(response.under, response.normal, amount: smoothstep(0.08, 0.5, luma))
        }
        return blend(response.normal, response.over, amount: smoothstep(0.5, 0.95, luma))
    }

    private static func blend(
        _ a: FilmResponseRecipe.ExposureState,
        _ b: FilmResponseRecipe.ExposureState,
        amount: Double
    ) -> FilmResponseRecipe.ExposureState {
        FilmResponseRecipe.ExposureState(
            contrast: mixValue(a.contrast, b.contrast, amount),
            saturation: mixValue(a.saturation, b.saturation, amount),
            red: mixValue(a.red, b.red, amount),
            green: mixValue(a.green, b.green, amount),
            blue: mixValue(a.blue, b.blue, amount),
            shadowLift: mixValue(a.shadowLift, b.shadowLift, amount),
            highlightCompression: mixValue(a.highlightCompression, b.highlightCompression, amount),
            density: mixValue(a.density, b.density, amount)
        )
    }

    private static func remapBlackWhite(_ value: Double, black: Double, white: Double) -> Double {
        let upper = max(black + 0.08, white)
        return (value - black) / (upper - black)
    }
}

private func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
    let x = clamped((value - edge0) / (edge1 - edge0), 0, 1)
    return x * x * (3 - 2 * x)
}

private func mixValue(_ a: Double, _ b: Double, _ amount: Double) -> Double {
    a * (1 - clamped(amount, 0, 1)) + b * clamped(amount, 0, 1)
}
