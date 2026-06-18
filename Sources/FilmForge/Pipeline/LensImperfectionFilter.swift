import AppKit
import CoreImage
import Foundation

struct LensImperfectionFilter {
    func applyLens(
        to image: CIImage,
        vignette: VignetteProfile,
        lens: LensProfile,
        flatness: FilmFlatnessProfile,
        randomness: RandomnessProfile,
        intensity: Double,
        seed: Double
    ) -> CIImage {
        var output = image
        if lens.enabled {
            if lens.compactBlur > 0 {
                output = output
                    .clampedToExtent()
                    .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: lens.compactBlur * 2.2 * intensity])
                    .cropped(to: image.extent)
            }
            if lens.edgeSoftness > 0 {
                output = applyEdgeSoftness(output, amount: lens.edgeSoftness * intensity * 0.55)
            }
            if lens.chromaticAberration > 0 {
                output = applyChromaticAberration(output, amount: lens.chromaticAberration * intensity * 0.35)
            }
        }

        if flatness.enabled, flatness.intensity > 0 {
            output = applyFilmFlatness(output, profile: flatness, intensity: intensity, seed: seed)
        }

        if vignette.enabled, vignette.intensity > 0 {
            output = applyVignette(output, vignette: vignette, intensity: intensity)
        }

        return output.cropped(to: image.extent)
    }

    func applyArtefacts(
        to image: CIImage,
        dust: DustProfile,
        stamp: DateStampProfile,
        scan: LabScanProfile,
        randomness: RandomnessProfile,
        intensity: Double,
        seed: Double
    ) -> CIImage {
        var output = image
        if dust.enabled {
            output = applyDustAndScratchesInternal(to: output, dust: dust, randomness: randomness, intensity: intensity, seed: seed)
            if dust.lightLeakAmount > 0 {
                output = applyLightLeaksInternal(to: output, amount: dust.lightLeakAmount * intensity, randomness: randomness, seed: seed)
            }
        }

        if scan.enabled {
            output = applyLabScanInternal(to: output, profile: scan, intensity: intensity, seed: seed)
        }

        if stamp.enabled, !stamp.text.isEmpty {
            output = applyDateStampInternal(to: output, stamp: stamp, randomness: randomness, intensity: intensity, seed: seed)
        }

        return output.cropped(to: image.extent)
    }

    // MARK: - Chromatic Aberration (radial, zero at center, max at edges)

    private func applyChromaticAberration(_ image: CIImage, amount: Double) -> CIImage {
        let shift = CGFloat(amount * 1.8)
        let red = image.transformed(by: CGAffineTransform(translationX: shift, y: 0))
        let blue = image.transformed(by: CGAffineTransform(translationX: -shift, y: 0))
        return Self.aberrationKernel.apply(
            extent: image.extent,
            arguments: [image, red, blue, CGFloat(amount), image.extent.width, image.extent.height]
        ) ?? image
    }

    // MARK: - Asymmetric Wavelength-Dependent Vignette

    private func applyVignette(_ image: CIImage, vignette: VignetteProfile, intensity: Double) -> CIImage {
        Self.vignetteKernel.apply(
            extent: image.extent,
            arguments: [
                image,
                CGFloat(vignette.intensity * intensity * 0.45),
                CGFloat(vignette.radius),
                CGFloat(vignette.softness),
                CGFloat(vignette.centerX),
                CGFloat(vignette.centerY),
                CGFloat(vignette.blueBias),
                image.extent.width,
                image.extent.height
            ]
        ) ?? image
    }

    // MARK: - Film Flatness (subtle random blur map)

    private func applyFilmFlatness(_ image: CIImage, profile: FilmFlatnessProfile, intensity: Double, seed: Double) -> CIImage {
        let offsetX = CGFloat(Self.random(seed, salt: 51) * 3000)
        let offsetY = CGFloat(Self.random(seed, salt: 52) * 3000)
        let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            .cropped(to: image.extent) ?? image

        let blurredNoise = noise
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(8, 60 * profile.frequency)])
            .cropped(to: image.extent)

        let blurredBase = image
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: profile.intensity * intensity * 3.5])
            .cropped(to: image.extent)

        return Self.flatnessKernel.apply(
            extent: image.extent,
            arguments: [image, blurredBase, blurredNoise, CGFloat(profile.intensity * intensity * 0.55)]
        ) ?? image
    }

    // MARK: - Lab Scan Simulation

    func applyLabScanInternal(to image: CIImage, profile: LabScanProfile, intensity: Double, seed: Double) -> CIImage {
        let offsetX = CGFloat(Self.random(seed, salt: 61) * 3000)
        let offsetY = CGFloat(Self.random(seed, salt: 62) * 3000)
        let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            .cropped(to: image.extent) ?? image

        return Self.labScanKernel.apply(
            extent: image.extent,
            arguments: [
                image,
                noise,
                CGFloat(profile.shadowColorShift * intensity),
                CGFloat(profile.scannerNoiseAmount * intensity)
            ]
        ) ?? image
    }

    // MARK: - Edge Softness

    private func applyEdgeSoftness(_ image: CIImage, amount: Double) -> CIImage {
        let blurred = image
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: amount * 8])
            .cropped(to: image.extent)

        return Self.edgeMaskKernel.apply(
            extent: image.extent,
            arguments: [image, blurred, CGFloat(amount), image.extent.width, image.extent.height]
        ) ?? image
    }

    // MARK: - Dust & Scratches

    func applyDustAndScratchesInternal(to image: CIImage, dust: DustProfile, randomness: RandomnessProfile, intensity: Double, seed: Double) -> CIImage {
        let offsetX = CGFloat(Self.random(seed, salt: 21) * 3000)
        let offsetY = CGFloat(Self.random(seed, salt: 22) * 3000)
        let dustJitter = randomness.enabled ? 1 + (Self.random(seed, salt: 23) - 0.5) * randomness.dustJitter : 1
        let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            .cropped(to: image.extent) ?? image
        return Self.dustKernel.apply(
            extent: image.extent,
            arguments: [image, noise, CGFloat(dust.dustAmount * intensity * dustJitter), CGFloat(dust.scratchAmount * intensity * dustJitter)]
        ) ?? image
    }

    // MARK: - Light Leaks (multiple leak sources, streak + bloom patterns)

    func applyLightLeaksInternal(to image: CIImage, amount: Double, randomness: RandomnessProfile, seed: Double) -> CIImage {
        let jitter = randomness.enabled ? randomness.lightLeakJitter : 0
        var result = image
        let leakCount = amount > 0.25 ? 3 : (amount > 0.12 ? 2 : 1)

        for i in 0..<leakCount {
            let leakSeed = seed + Double(i) * 137.0
            result = applySingleLeak(result, amount: amount / Double(leakCount), jitter: jitter, seed: leakSeed, index: i)
        }

        return result.cropped(to: image.extent)
    }

    private func applySingleLeak(_ image: CIImage, amount: Double, jitter: Double, seed: Double, index: Int) -> CIImage {
        let sideRand = Self.random(seed, salt: 31 + Double(index) * 7)
        let side = sideRand > 0.5 ? 1.0 : -1.0

        let isStreak = Self.random(seed, salt: 38 + Double(index) * 11) > 0.48
        let topBias = Self.random(seed, salt: 35 + Double(index) * 3) > 0.55
        let yDrift = CGFloat((Self.random(seed, salt: 32 + Double(index) * 5) - 0.5) * 0.34 * jitter) * image.extent.height
        let widthRatio = isStreak ? CGFloat(0.08 + Self.random(seed, salt: 33 + Double(index) * 3) * 0.14) : CGFloat(0.22 + Self.random(seed, salt: 33 + Double(index) * 3) * 0.28)
        let width = widthRatio * image.extent.width
        let strength = min(1.0, amount * 8.0 * (1 + (Self.random(seed, salt: 34 + Double(index) * 3) - 0.5) * jitter))
        let startX = side > 0 ? image.extent.minX : image.extent.maxX
        let endX = startX + CGFloat(side) * width
        let leakY = topBias
            ? image.extent.maxY - image.extent.height * CGFloat(0.08 + Self.random(seed, salt: 36 + Double(index) * 5) * 0.24)
            : image.extent.midY + yDrift

        let red = Float(0.92 + Self.random(seed, salt: 37 + Double(index) * 2) * 0.08)
        let green = Float(0.14 + Self.random(seed, salt: 37 + Double(index) * 2 + 0.3) * 0.22)
        let blue = Float(0.02 + Self.random(seed, salt: 37 + Double(index) * 2 + 0.6) * 0.06)

        let gradient = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: startX, y: leakY),
            "inputPoint1": CIVector(x: endX, y: leakY - yDrift * 0.35),
            "inputColor0": CIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: strength),
            "inputColor1": CIColor(red: 1.0, green: 0.55, blue: 0.12, alpha: 0)
        ])?.outputImage?.cropped(to: image.extent) ?? image

        if isStreak {
            return Self.streakLeakKernel.apply(
                extent: image.extent,
                arguments: [image, gradient, CGFloat(strength), image.extent.width, image.extent.height, CGFloat(topBias ? 1.0 : 0.0), CGFloat(side)]
            ) ?? gradient.applyingFilter("CIScreenBlendMode", parameters: [kCIInputBackgroundImageKey: image])
        } else {
            return Self.leakShapeKernel.apply(
                extent: image.extent,
                arguments: [image, gradient, CGFloat(strength), image.extent.width, image.extent.height, CGFloat(topBias ? 1.0 : 0.0)]
            ) ?? gradient.applyingFilter("CIScreenBlendMode", parameters: [kCIInputBackgroundImageKey: image])
        }
    }

    // MARK: - Date Stamp

    func applyDateStampInternal(to image: CIImage, stamp: DateStampProfile, randomness: RandomnessProfile, intensity: Double, seed: Double) -> CIImage {
        let scale = max(image.extent.width, image.extent.height) / 1800
        let font = NSFont.monospacedDigitSystemFont(ofSize: max(20, 30 * scale), weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 1, green: 0.55, blue: 0.12, alpha: stamp.opacity * intensity * 0.58)
        ]
        let text = NSAttributedString(string: stamp.text, attributes: attributes)
        let imageSize = text.size()
        let nsImage = NSImage(size: imageSize)
        nsImage.lockFocus()
        text.draw(in: NSRect(origin: .zero, size: imageSize))
        nsImage.unlockFocus()
        let textImage = CIImage(data: nsImage.tiffRepresentation ?? Data()) ?? CIImage.empty()
        let jitter = randomness.enabled ? randomness.dateStampJitter : 0
        let jitterX = CGFloat((Self.random(seed, salt: 41) - 0.5) * 10 * jitter) * scale
        let jitterY = CGFloat((Self.random(seed, salt: 42) - 0.5) * 7 * jitter) * scale

        let placed = textImage.transformed(by: CGAffineTransform(
            translationX: image.extent.maxX - imageSize.width - 34 * scale + jitterX,
            y: image.extent.minY + 28 * scale + jitterY
        ))
        return placed.composited(over: image)
    }

    // MARK: - Random

    private static func random(_ seed: Double, salt: Double) -> Double {
        let value = sin(seed * 12.9898 + salt * 78.233) * 43758.5453
        return value - floor(value)
    }

    // MARK: - Kernels

    private static let aberrationKernel = CIColorKernel(source: """
    kernel vec4 aberrate(__sample source, __sample redShift, __sample blueShift, float amount, float width, float height) {
        vec2 p = destCoord() / vec2(width, height);
        float d = distance(p, vec2(0.5));
        float radialAmount = amount * smoothstep(0.15, 0.95, d * 1.6);
        vec3 color = source.rgb;
        color.r = mix(color.r, redShift.r, radialAmount);
        color.b = mix(color.b, blueShift.b, radialAmount);
        return vec4(color, source.a);
    }
    """)!

    private static let vignetteKernel = CIColorKernel(source: """
    kernel vec4 filmVignette(__sample source, float intensity, float radius, float softness, float centerX, float centerY, float blueBias, float width, float height) {
        vec2 p = destCoord() / vec2(width, height);
        vec2 center = vec2(centerX, centerY);
        float d = distance(p, center) / max(radius * 0.52, 0.01);
        float v = smoothstep(radius * 0.42, radius * (0.42 + softness * 0.44), d) * intensity;
        vec3 result = source.rgb * (1.0 - v);
        result.b *= 1.0 - v * blueBias * 0.45;
        return vec4(clamp(result, 0.0, 1.0), source.a);
    }
    """)!

    private static let flatnessKernel = CIColorKernel(source: """
    kernel vec4 filmFlatness(__sample source, __sample blurred, __sample noise, float amount) {
        float variation = noise.r * 2.0 - 1.0;
        float localAmount = amount * (0.5 + variation * 0.5);
        return vec4(mix(source.rgb, blurred.rgb, clamp(localAmount, 0.0, 0.55)), source.a);
    }
    """)!

    private static let labScanKernel = CIColorKernel(source: """
    kernel vec4 labScan(__sample source, __sample noise, float shadowShift, float scannerNoise) {
        float l = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
        float shadow = 1.0 - smoothstep(0.04, 0.30, l);
        float colorNoise = noise.g * 2.0 - 1.0;
        vec3 shifted = source.rgb;
        shifted.g += colorNoise * shadowShift * shadow * 0.06;
        shifted.r -= colorNoise * shadowShift * shadow * 0.028;
        shifted.b += colorNoise * shadowShift * shadow * 0.032;
        shifted.g -= noise.r * scannerNoise * 0.012;
        shifted.r += noise.b * scannerNoise * 0.010;
        vec3 banded = floor(shifted * 64.0 + 0.5) / 64.0;
        shifted = mix(shifted, banded, scannerNoise * shadow * 0.38);
        return vec4(clamp(shifted, 0.0, 1.0), source.a);
    }
    """)!

    private static let edgeMaskKernel = CIColorKernel(source: """
    kernel vec4 edgeSoft(__sample source, __sample blurred, float amount, float width, float height) {
        vec2 coord = destCoord();
        vec2 size = vec2(width, height);
        vec2 p = coord / size;
        float d = distance(p, vec2(0.5));
        float m = smoothstep(0.28, 0.72, d) * amount;
        return vec4(mix(source.rgb, blurred.rgb, m), source.a);
    }
    """)!

    private static let leakShapeKernel = CIColorKernel(source: """
    kernel vec4 leakShape(__sample source, __sample leak, float amount, float width, float height, float topBias) {
        vec2 p = destCoord() / vec2(width, height);
        float top = smoothstep(0.58, 1.0, p.y) * topBias;
        float verticalBand = 1.0 - smoothstep(0.0, 0.72, abs(p.y - 0.52));
        float flareMask = clamp(verticalBand + top * 0.8, 0.0, 1.0);
        float l = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
        vec3 warmed = source.rgb + leak.rgb * (0.40 + (1.0 - l) * 0.32) * flareMask;
        vec3 screened = 1.0 - (1.0 - source.rgb) * (1.0 - leak.rgb * (0.75 + amount));
        vec3 result = mix(source.rgb, screened, clamp(leak.a * (0.85 + amount) * flareMask, 0.0, 0.78));
        result = mix(result, warmed, clamp(leak.a * 0.18, 0.0, 0.35));
        return vec4(clamp(result, 0.0, 1.0), source.a);
    }
    """)!

    private static let streakLeakKernel = CIColorKernel(source: """
    kernel vec4 streakLeak(__sample source, __sample leak, float amount, float width, float height, float topBias, float side) {
        vec2 p = destCoord() / vec2(width, height);
        float fromSide = side > 0.0 ? p.x : (1.0 - p.x);
        float edge = smoothstep(0.0, 0.35, fromSide);
        float thinStreak = 1.0 - smoothstep(0.0, 0.06, abs(fromSide - leak.a * 0.18));
        float streakMask = clamp(thinStreak * edge * leak.a, 0.0, 1.0);
        vec3 screened = 1.0 - (1.0 - source.rgb) * (1.0 - leak.rgb * (0.65 + amount) * streakMask);
        float l = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
        screened += leak.rgb * streakMask * amount * (1.0 - l) * 0.28;
        return vec4(clamp(screened, 0.0, 1.0), source.a);
    }
    """)!

    private static let dustKernel = CIColorKernel(source: """
    kernel vec4 dust(__sample source, __sample noise, float dustAmount, float scratchAmount) {
        float speck = step(1.0 - dustAmount * 0.55, noise.r) * 0.30;
        float dark = step(1.0 - dustAmount * 0.22, noise.g) * 0.35;
        float scratch = step(0.998 - scratchAmount * 0.06, fract(destCoord().x * 0.017 + noise.b * 0.06)) * 0.5;
        vec3 result = source.rgb;
        result = mix(result, vec3(0.96), speck);
        result = mix(result, vec3(0.02), dark);
        vec3 scratchColor = mix(source.rgb, vec3(1.0), 0.4);
        result = mix(result, scratchColor, scratch);
        return vec4(clamp(result, 0.0, 1.0), source.a);
    }
    """)!
}
