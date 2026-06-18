import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

struct FilmPipeline {
    var context: CIContext
    var lutLoader = LUTLoader()
    var digitalTaming = DigitalTamingFilter()
    var sceneAnalyzer: SceneAnalyzer
    var toneCurve = ToneCurveFilter()
    var halation = HalationFilter()
    var bloom = BloomFilter()
    var grain = GrainFilter()
    var lens = LensImperfectionFilter()

    init(context: CIContext = RenderContext.shared.context) {
        self.context = context
        self.sceneAnalyzer = SceneAnalyzer(context: context)
    }

    func render(
        input: CIImage,
        profile: FilmLookProfile,
        componentIntensities: LookComponentIntensities,
        toggles: PipelineToggles,
        exportSettings: ExportSettings = ExportSettings(),
        targetExtent: CGRect? = nil,
        renderSeed: Double? = nil
    ) -> CIImage {
        let extent = targetExtent ?? input.extent
        let controls = componentIntensities.clamped()
        let seed = renderSeed ?? exportSettings.renderSeed
        let original = input.cropped(to: input.extent)
        let scene = sceneAnalyzer.analyze(original)
        let adaptationIntensity = max(controls.tone, controls.colour, controls.lut, controls.grain, controls.glow, controls.lens, controls.artefacts)
        let profile = adapt(profile: profile, for: scene, intensity: adaptationIntensity)

        // Per-import exposure jitter: deterministic from seed, ±0.15 EV
        let exposureJitter = sin(seed * 17.23) * 0.15

        var image = normalize(input: original, profile: profile, intensity: controls.tone, jitter: exposureJitter)

        if exportSettings.lutOnly {
            return applyLUT(to: image, original: image, profile: profile, amount: profile.lutIntensity * controls.lut, scene: scene)
                .cropped(to: extent)
        }

        // Stage 1: Digital taming (de-phone-ification)
        image = digitalTaming.apply(to: image, profile: profile.digitalTamingProfile, intensity: max(controls.tone, controls.lens))

        // Stage 2: Grain (film negative texture — must run BEFORE tone curve per Newson et al.)
        // Grain modulates density domain, then the tone curve's shoulder/black crush naturally
        // compress it in highlights and shadows, weaving it into the image rather than pasting over.
        if toggles.grain {
            image = grain.apply(to: image, profile: profile.grainProfile, intensity: controls.grain, softness: controls.softness, seed: seed)
        }

        // Stage 2.5: Chemical micro-contrast (acutance / Mackie line simulation)
        // Film's adjacency effects: fresh developer diffuses across edges, creating
        // soft-but-sharp transitions that give film its characteristic 3D feel.
        image = applyAcutance(to: image, intensity: controls.tone * 0.35)

        // Stage 3: Tone curve + print response (development & printing)
        if toggles.tone {
            image = toneCurve.apply(to: image, profile: profile, intensity: controls.tone)
            image = applyPrintResponse(to: image, profile: profile.printProfile, intensity: controls.tone)
        }

        // Stage 4: Lens effects (capture-time optical effects, after development)
        if toggles.lens {
            image = lens.applyLens(
                to: image,
                vignette: profile.vignetteProfile,
                lens: profile.lensProfile,
                flatness: profile.filmFlatnessProfile,
                randomness: profile.randomnessProfile,
                intensity: controls.lens,
                seed: seed
            )
        }

        // Stage 5: Camera response + colour bias + LUT (negative/emulsion colour)
        image = applyCameraResponse(to: image, profile: profile.cameraResponseProfile, scene: scene, intensity: controls.colour)
        image = applyColourBias(to: image, profile: profile, intensity: controls.colour)

        if toggles.lut {
            image = applyLUT(to: image, original: image, profile: profile, amount: profile.lutIntensity * controls.lut, scene: scene)
        }

        // Stage 6: Halation + bloom (print-stage glow, share a highlight mask)
        if toggles.halation || toggles.bloom {
            let sharedMask: CIImage?
            if toggles.halation, toggles.bloom {
                let avgThreshold = (profile.halationProfile.threshold + profile.bloomProfile.threshold) * 0.5
                let avgBlend = (profile.halationProfile.blend + profile.bloomProfile.softness) * 0.5
                sharedMask = HalationFilter.makeSharedMask(
                    image: image,
                    threshold: avgThreshold,
                    blend: avgBlend,
                    radius: profile.halationProfile.radius
                )
            } else {
                sharedMask = nil
            }

            if toggles.halation {
                image = halation.apply(to: image, profile: profile.halationProfile, intensity: controls.glow, sharedMask: sharedMask)
            }
            if toggles.bloom {
                image = bloom.apply(to: image, profile: profile.bloomProfile, intensity: controls.glow, sharedMask: sharedMask)
            }
        }

        // Stage 6.5: Cross-processing (X-Pro) — slide film in C-41 chemicals
        if toggles.xpro {
            image = Self.crossProcessKernel.apply(
                extent: image.extent,
                arguments: [image, CGFloat(controls.colour * 0.85)]
            ) ?? image
        }

        // Stage 7: Artefacts — modular, individual toggles for each element
        if toggles.artefacts {
            // Dust & scratches
            if toggles.dustScratches, profile.dustProfile.enabled {
                image = lens.applyDustAndScratchesInternal(
                    to: image,
                    dust: profile.dustProfile,
                    randomness: profile.randomnessProfile,
                    intensity: controls.artefacts,
                    seed: seed
                )
            }
            // Light leaks
            if toggles.lightLeaks, profile.dustProfile.enabled, profile.dustProfile.lightLeakAmount > 0 {
                image = lens.applyLightLeaksInternal(
                    to: image,
                    amount: profile.dustProfile.lightLeakAmount * controls.artefacts,
                    randomness: profile.randomnessProfile,
                    seed: seed
                )
            }
            // Lab scan
            if toggles.labScan, profile.labScanProfile.enabled {
                image = lens.applyLabScanInternal(
                    to: image,
                    profile: profile.labScanProfile,
                    intensity: controls.artefacts,
                    seed: seed
                )
            }
            // Date stamp
            if toggles.dateStamp, profile.dateStampProfile.enabled, !profile.dateStampProfile.text.isEmpty {
                image = lens.applyDateStampInternal(
                    to: image,
                    stamp: profile.dateStampProfile,
                    randomness: profile.randomnessProfile,
                    intensity: controls.artefacts,
                    seed: seed
                )
            }
        }

        return image.cropped(to: extent)
    }

    private func normalize(input: CIImage, profile: FilmLookProfile, intensity: Double, jitter: Double) -> CIImage {
        // Push/pull nudges exposure before the tone curve handles density and contrast.
        let pushExposure = profile.pushPull * 0.30

        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = input
        exposure.ev = Float((profile.baseExposure + jitter + pushExposure) * intensity)
        guard var image = exposure.outputImage else { return input }

        let clamp = CIFilter.colorClamp()
        clamp.inputImage = image
        clamp.minComponents = CIVector(x: 0, y: 0, z: 0, w: 0)
        clamp.maxComponents = CIVector(x: 4, y: 4, z: 4, w: 1)
        image = clamp.outputImage ?? image
        return image
    }

    private func applyColourBias(to image: CIImage, profile: FilmLookProfile, intensity: Double) -> CIImage {
        var output = image

        // Exposure-dependent color balance: film shifts warm when overexposed (cyan dyes block up),
        // cool/magenta when underexposed. This links white balance to exposure for authentic behavior.
        let exposureColorShift = (profile.baseExposure - 0.05) * 420
        let exposureTintShift = (profile.baseExposure - 0.05) * 35

        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = output
        temp.neutral = CIVector(x: 6500, y: 0)
        temp.targetNeutral = CIVector(
            x: 6500 + CGFloat((profile.colourTemperatureBias + exposureColorShift) * intensity * 0.34),
            y: CGFloat((profile.tintBias + exposureTintShift) * intensity * 0.40)
        )
        output = temp.outputImage ?? output

        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = Float(1 + ((profile.saturation - 1) * intensity * 0.55))
        controls.contrast = Float(1 + ((profile.contrast - 1) * 0.12 * intensity))
        controls.brightness = 0
        output = controls.outputImage ?? output

        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = output
        vibrance.amount = Float(profile.vibrance * intensity * 0.35)
        return vibrance.outputImage ?? output
    }

    private func adapt(profile: FilmLookProfile, for scene: SceneAnalysis, intensity: Double) -> FilmLookProfile {
        var adapted = profile
        let darkScene = max(0, min((0.38 - scene.meanLuma) / 0.38, 1))
        let brightScene = max(0, min((scene.meanLuma - 0.58) / 0.42, 1))
        let highlightPressure = max(0, min((scene.maxLuma - 0.86) / 0.54, 1))
        let warmScene = max(0, min(scene.warmth * 0.55, 1))
        let coolScene = max(0, min(-scene.warmth * 0.55, 1))
        let saturatedScene = max(0, min((scene.saturation - 0.22) / 0.55, 1))
        let disposable = profile.id.hasPrefix("kodak-") || profile.id.hasPrefix("fuji-") || profile.id.hasPrefix("huji-") || profile.id.contains("disposable")
        let cameraApp = disposable || profile.id.hasPrefix("dazz-")

        // Bolder base adaptation
        let dMult: Double = disposable ? 2.8 : 1.0
        let aMult: Double = cameraApp ? 2.2 : 1.0

        adapted.baseExposure += darkScene * 0.20 * dMult - brightScene * 0.12 * dMult
        adapted.shoulderStrength += highlightPressure * (disposable ? 0.24 : 0.18)
        adapted.printProfile.highlightRolloff += highlightPressure * (disposable ? 0.26 : 0.18)
        adapted.printProfile.highlightDesaturation += saturatedScene * 0.18 * dMult + highlightPressure * 0.14 * dMult
        adapted.cameraResponseProfile.redChannelBloom += highlightPressure * (cameraApp ? 0.28 : 0.10)
        adapted.cameraResponseProfile.dyeContamination += saturatedScene * (cameraApp ? 0.18 : 0.07) * aMult
        adapted.cameraResponseProfile.scanFade += brightScene * (cameraApp ? 0.14 : 0.06) - darkScene * 0.05 * aMult
        adapted.bloomProfile.threshold += brightScene * 0.08 * dMult - darkScene * 0.06 * dMult
        adapted.halationProfile.threshold += brightScene * 0.07 * dMult - darkScene * 0.07 * dMult
        adapted.grainProfile.strength *= 1 + darkScene * 0.45 * dMult - brightScene * 0.12 * dMult
        adapted.grainProfile.shadowAmount *= 1 + darkScene * 0.30 * dMult
        adapted.grainProfile.highlightAmount *= 1 + highlightPressure * 0.22 * dMult
        adapted.digitalTamingProfile.localHDRCompression += highlightPressure * 0.20 * dMult
        adapted.digitalTamingProfile.clarityReduction += highlightPressure * 0.12 * dMult
        adapted.lutIntensity *= 1 - saturatedScene * 0.08 * dMult

        if disposable {
            adapted.vignetteProfile.intensity *= 1 + darkScene * 0.28
            adapted.dustProfile.lightLeakAmount *= 1 + brightScene * 0.38
            adapted.cameraResponseProfile.cheapness += darkScene * 0.18 + highlightPressure * 0.10
            adapted.grainProfile.roughness *= 1 + darkScene * 0.24
            adapted.lensProfile.edgeSoftness *= 1 + darkScene * 0.16
            adapted.bloomProfile.intensity *= 1 + highlightPressure * 0.28 * dMult
            adapted.halationProfile.intensity *= 1 + highlightPressure * 0.22 * dMult
            adapted.labScanProfile.scannerNoiseAmount *= 1 + darkScene * 0.26
            adapted.filmFlatnessProfile.intensity *= 1 + darkScene * 0.32
        }

        adapted.colourTemperatureBias += coolScene * 120 - warmScene * 85

        // Push/pull processing: pushing increases grain RMS, crushes blacks,
        // elevates green shadow tint, and boosts color separation.
        // Pulling reduces contrast and softens grain.
        if profile.pushPull != 0 {
            adapted.grainProfile.strength *= 1.0 + profile.pushPull * 0.35
            adapted.grainProfile.roughness *= 1.0 + profile.pushPull * 0.20
            adapted.toeStrength += profile.pushPull * 0.06
            adapted.shoulderStrength += profile.pushPull * 0.08
            adapted.cameraResponseProfile.colorSeparation += profile.pushPull * 0.12
            adapted.cameraResponseProfile.greenBias += profile.pushPull * 0.025
            adapted.contrast += profile.pushPull * 0.15
        }

        return adapted
    }

    private func applyCameraResponse(to image: CIImage, profile: CameraResponseProfile, scene: SceneAnalysis, intensity: Double) -> CIImage {
        guard profile.enabled else { return image }
        let sceneWarmth = max(-1, min(scene.warmth, 1))
        let sceneSaturation = max(0, min(scene.saturation, 1))
        return Self.cameraResponseKernel.apply(
            extent: image.extent,
            arguments: [
                image,
                CGFloat(profile.colorSeparation * intensity),
                CGFloat(profile.crossProcess * intensity),
                CGFloat(profile.cyanShadow * intensity),
                CGFloat(profile.warmHighlight * intensity),
                CGFloat(profile.redChannelBloom * intensity),
                CGFloat(profile.greenBias * intensity),
                CGFloat(profile.blueBias * intensity),
                CGFloat(profile.dyeContamination * intensity),
                CGFloat(profile.scanFade * intensity),
                CGFloat(profile.cheapness * intensity),
                CGFloat(sceneWarmth),
                CGFloat(sceneSaturation)
            ]
        ) ?? image
    }

    private func applyAcutance(to image: CIImage, intensity: Double) -> CIImage {
        guard intensity > 0.005 else { return image }
        // Chemical adjacency effect (Mackie lines): developer diffuses across edges.
        // Difference-of-Gaussians creates soft edge enhancement without digital sharpness.
        let fine = image
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.8 * intensity])
            .cropped(to: image.extent)
        let broad = image
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 8.0 * intensity])
            .cropped(to: image.extent)
        return Self.acutanceKernel.apply(
            extent: image.extent,
            arguments: [image, fine, broad, CGFloat(intensity)]
        ) ?? image
    }

    private func applyPrintResponse(to image: CIImage, profile: PrintResponseProfile, intensity: Double) -> CIImage {
        Self.printKernel.apply(
            extent: image.extent,
            arguments: [
                image,
                CGFloat(profile.highlightDesaturation * intensity),
                CGFloat(profile.highlightRolloff * intensity),
                CGFloat(profile.paperBlack),
                CGFloat(profile.paperWhite)
            ]
        ) ?? image
    }

    private func applyLUT(to image: CIImage, original: CIImage, profile: FilmLookProfile, amount: Double, scene: SceneAnalysis) -> CIImage {
        guard amount > 0.001 else { return image }
        let cube = lutLoader.loadCube(name: profile.lutName, url: profile.lutURL, fallbackProfileID: profile.id)
        guard let filtered = lutLoader.apply(cube: cube, to: image) else { return image }

        // Adaptive LUT blending: vary LUT strength based on scene analysis
        // Warm scenes get stronger LUT (film looks best in warm light)
        // Cool/dark scenes get slightly reduced LUT to avoid overcooking
        let warmScene = max(0, min(scene.warmth * 0.55, 1))
        let darkScene = max(0, min((0.38 - scene.meanLuma) / 0.38, 1))
        let brightScene = max(0, min((scene.meanLuma - 0.58) / 0.42, 1))
        let adaptationScale = 1.0 + warmScene * 0.25 - darkScene * 0.18 - brightScene * 0.08

        let builtInScale: Double
        if profile.lutURL != nil {
            builtInScale = 1.0
        } else if profile.id.hasPrefix("huji-") {
            builtInScale = 0.54
        } else if profile.id.hasPrefix("kodak-") || profile.id.hasPrefix("fuji-") {
            builtInScale = 0.48
        } else if profile.id == "disposable-flash" || profile.id == "warm-disposable" {
            builtInScale = 0.44
        } else if profile.id.hasPrefix("dazz-") {
            builtInScale = 0.40
        } else if profile.id == "slide-chrome" || profile.id == "silver-gelatin" {
            builtInScale = 0.34
        } else {
            builtInScale = 0.28
        }

        let finalAmount = max(0, min(amount * builtInScale * adaptationScale, 1))
        return LUTLoader.blendKernel.apply(
            extent: image.extent,
            arguments: [image, filtered, CGFloat(finalAmount)]
        ) ?? filtered
    }
}

private extension FilmPipeline {
    static let acutanceKernel = CIColorKernel(source: """
    kernel vec4 acutance(__sample source, __sample fine, __sample broad, float intensity) {
        // Difference-of-Gaussians: edge-aware micro-contrast without harshness.
        // Film's adjacency effects create soft-but-sharp transitions — not digital sharpening.
        vec3 dog = fine.rgb - broad.rgb;
        float edge = smoothstep(0.018, 0.10, abs(dot(dog, vec3(0.3333))));
        vec3 enhanced = source.rgb + dog * edge * intensity * 0.42;
        return vec4(clamp(enhanced, 0.0, 1.0), source.a);
    }
    """)!

    static let printKernel = CIColorKernel(source: """
    kernel vec4 printResponse(__sample source, float desat, float rolloff, float paperBlack, float paperWhite) {
        vec3 c = max(source.rgb, vec3(0.0));
        float mx = max(max(c.r, c.g), c.b);
        float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
        float high = smoothstep(0.68, 1.16, mx);

        float rolledL = 1.0 - exp(-l * (1.0 + rolloff * 1.35));
        vec3 rolled = c * (rolledL / max(l, 0.0001));

        // Subtractive highlight desaturation: each channel independently approaches paper white
        // (D-min of the paper). Unlike additive lerp-to-luma, this naturally rolls highlights
        // to creamy white without neon-colored blowouts — exactly how analog prints behave.
        vec3 dMin = vec3(paperWhite);
        float desatStrength = high * desat * 0.48;
        vec3 subtractive = mix(rolled, dMin, desatStrength);

        // Highlight rolloff: compress toward paper white at extreme highlights
        float rolloffStrength = high * rolloff * 0.18;
        subtractive = mix(subtractive, dMin, rolloffStrength);

        // Paper range: scale between paper black and paper white
        vec3 final = subtractive * max(paperWhite - paperBlack, 0.001) + vec3(paperBlack);
        return vec4(clamp(final, 0.0, 1.0), source.a);
    }
    """)!

    static let crossProcessKernel = CIColorKernel(source: """
    kernel vec4 xpro(__sample source, float amount) {
        // Cross-processing (X-Pro): slide film in C-41 chemicals.
        // No orange mask compensation, wild color shifts, extreme contrast.
        vec3 c = max(source.rgb, vec3(0.0));
        float l = dot(c, vec3(0.2126, 0.7152, 0.0722));

        // Invert to negative (simulate slide film base), apply wrong chemistry,
        // invert back to positive. The lack of orange mask creates wild casts.
        vec3 inverted = vec3(1.0) - c;
        inverted.r = pow(inverted.r, 0.75 + amount * 0.25);
        inverted.g = pow(inverted.g, 0.85 - amount * 0.15);
        inverted.b = pow(inverted.b, 0.60 + amount * 0.30);
        inverted += vec3(0.04, -0.06, 0.10) * amount;
        vec3 result = vec3(1.0) - inverted;

        // Extreme contrast from wrong developer
        result = pow(max(result, vec3(0.0)), vec3(1.0 + amount * 0.45));

        // Color crossover: cyan/green shadow shift, golden highlight shift
        float shadow = 1.0 - smoothstep(0.08, 0.48, l);
        float high = smoothstep(0.56, 0.98, l);
        result.g += shadow * amount * 0.08;
        result.b -= shadow * amount * 0.04;
        result.r += high * amount * 0.06;
        result.g += high * amount * 0.03;

        return vec4(clamp(result, 0.0, 1.0), source.a);
    }
    """)!

    static let cameraResponseKernel = CIColorKernel(source: """
    kernel vec4 cameraResponse(
        __sample source,
        float separation,
        float crossProcess,
        float cyanShadow,
        float warmHighlight,
        float redBloom,
        float greenBias,
        float blueBias,
        float contamination,
        float scanFade,
        float cheapness,
        float sceneWarmth,
        float sceneSaturation
    ) {
        vec3 c = clamp(source.rgb, 0.0, 1.0);
        float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
        float shadow = 1.0 - smoothstep(0.08, 0.48, l);
        float mid = smoothstep(0.12, 0.42, l) * (1.0 - smoothstep(0.62, 0.94, l));
        float high = smoothstep(0.56, 0.98, l);
        float mx = max(max(c.r, c.g), c.b);
        float mn = min(min(c.r, c.g), c.b);
        float sat = mx - mn;

        vec3 neutral = vec3(l);
        vec3 separated = neutral + (c - neutral) * (1.0 + separation * (0.42 + mid * 0.30) - high * separation * 0.12);
        separated.r += sat * separation * 0.045;
        separated.g += (separated.g - l) * separation * 0.035;
        separated.b -= sat * separation * 0.030;

        vec3 crossed = separated;
        crossed.r = pow(max(crossed.r, 0.0), max(0.62, 1.0 - crossProcess * 0.20));
        crossed.g = pow(max(crossed.g, 0.0), 1.0 + crossProcess * 0.08);
        crossed.b = pow(max(crossed.b, 0.0), 1.0 + crossProcess * 0.18);
        crossed += vec3(0.010, -0.004, -0.012) * crossProcess;

        // True IIE (Interlayer Interimage Effects): DIR couplers release inhibitors
        // proportional to local contrast, not just absolute density. Red layer development
        // suppresses green/blue development more aggressively at edges. Green development
        // inhibits red and blue via proportional inhibitor release.
        float redContrast = abs(crossed.r - l) * mid;
        float greenContrast = abs(crossed.g - l) * mid;
        crossed.g -= (max(0.0, crossed.r - 0.5) * 0.12 + redContrast * 0.08) * contamination;
        crossed.b -= (max(0.0, crossed.r - 0.5) * 0.08 + redContrast * 0.05) * contamination;
        crossed.r -= max(0.0, crossed.g - 0.5) * contamination * 0.04;
        crossed.b -= max(0.0, crossed.g - 0.5) * contamination * 0.03;
        // Red gets a subtle boost from green development (DIR coupler compensation)
        crossed.r += max(0.0, crossed.g - 0.5) * contamination * 0.06;

        vec3 shadowTint = vec3(-0.06, 0.026 + greenBias * 0.04, 0.085 + blueBias * 0.05) * cyanShadow * shadow;
        vec3 highTint = vec3(0.095 + redBloom * 0.04, 0.042, -0.045) * warmHighlight * high;
        crossed += shadowTint + highTint;

        float redPressure = smoothstep(0.50, 1.0, crossed.r) * high;
        crossed.r += redPressure * redBloom * 0.075;
        crossed.g += redPressure * redBloom * 0.018;
        crossed.b -= redPressure * redBloom * 0.032;

        vec3 dye = vec3(
            crossed.r + crossed.g * 0.035 - crossed.b * 0.014,
            crossed.g + crossed.r * 0.020 + crossed.b * 0.020,
            crossed.b + crossed.g * 0.028 - crossed.r * 0.018
        );
        crossed = mix(crossed, dye, contamination * (0.35 + sceneSaturation * 0.35));

        vec3 faded = mix(crossed, vec3(l), scanFade * (0.20 + high * 0.28));
        faded += vec3(0.020, 0.010, -0.010) * scanFade * high;
        faded += vec3(0.000, 0.012, 0.020) * scanFade * shadow * (1.0 - max(sceneWarmth, 0.0) * 0.35);

        float poster = floor(faded.r * 28.0 + 0.5) / 28.0;
        faded.r = mix(faded.r, poster, cheapness * high * 0.10);
        faded.g += cheapness * greenBias * 0.022 * (shadow + mid * 0.5);
        faded.b += cheapness * blueBias * 0.024 * shadow;
        faded = mix(faded, vec3(dot(faded, vec3(0.25, 0.65, 0.10))), cheapness * high * 0.045);

        return vec4(clamp(faded, 0.0, 1.0), source.a);
    }
    """)!
}

enum RenderContext {
    static let workingColorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
    static let outputColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    static let shared = RenderContextBox()
}

final class RenderContextBox {
    let context: CIContext

    init() {
        context = CIContext(options: [
            .workingColorSpace: RenderContext.workingColorSpace,
            .outputColorSpace: RenderContext.outputColorSpace,
            .cacheIntermediates: true,
            .name: "FilmForgeRenderContext"
        ])
    }
}
