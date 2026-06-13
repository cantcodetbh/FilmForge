import CoreGraphics
import CoreImage
import Foundation

protocol PipelineStage {
    var id: String { get }
    var backend: StageBackend { get }
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage
}

enum StageBackend: String {
    case builtInCoreImage
    case customCoreImageKernel
    case metalShader
    case cpuFallback
}

extension PipelineStage {
    var id: String { String(describing: Self.self) }
    var backend: StageBackend { .builtInCoreImage }
}

protocol CoreImageStage: PipelineStage {}
protocol CustomCIKernelStage: PipelineStage {}
protocol MetalStage: PipelineStage {}

extension CustomCIKernelStage {
    var backend: StageBackend { .customCoreImageKernel }
}

extension MetalStage {
    var backend: StageBackend { .metalShader }
}

final class ImagePipeline {
    private let stages: [PipelineStage] = [
        PreviewSizingStage(),
        DownsampleStage(),
        ExposureTemperatureStage(),
        LUTStage(),
        BaseColorStage(),
        SplitToneStage(),
        FilmicResponseStage(),
        ToneCurveStage(),
        BloomStage(),
        HalationStage(),
        LensStage(),
        ChromaticAberrationStage(),
        VignetteStage(),
        GrainStage(),
        DustStage(),
        BorderStage()
    ]

    func render(_ source: CIImage, context: RenderContext) throws -> CIImage {
        try stages.reduce(source) { image, stage in
            try stage.render(image, context: context)
        }
    }
}

struct PreviewSizingStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        guard case .preview(let maxLongEdge) = context.mode else { return image }
        let extent = image.extent
        let longEdge = max(extent.width, extent.height)
        guard longEdge > maxLongEdge, maxLongEdge > 0 else { return image }
        let scale = maxLongEdge / longEdge
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct DownsampleStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let value = context.profile.recipe.lens.downsample
        guard value < 0.98 else { return image }
        let scale = clamped(value, 0.35, 1)
        let small = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return small
            .transformed(by: CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
            .cropped(to: image.extent)
    }
}

struct ExposureTemperatureStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let adjustments = context.adjustments
        var output = image.applyingFilterIfAvailable("CIExposureAdjust", parameters: [
            kCIInputEVKey: adjustments.exposure + context.profile.recipe.color.exposure
        ])

        let recipe = context.profile.recipe.color
        let neutral = CIVector(x: 6500, y: 0)
        let target = CIVector(
            x: 6500 + (recipe.temperature + adjustments.temperature) * 900,
            y: (recipe.tint + adjustments.tint) * 80
        )
        output = output.applyingFilterIfAvailable("CITemperatureAndTint", parameters: [
            "inputNeutral": neutral,
            "inputTargetNeutral": target
        ])
        return output
    }
}

struct LUTStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipes = context.profile.recipe.luts.isEmpty
            ? [LUTRecipe(id: "generated-profile", source: .generatedProfile, dimension: 16, strength: 0.52)]
            : context.profile.recipe.luts

        return try recipes.reduce(image) { current, recipe in
            let lut: LUT3D
            switch recipe.source {
            case .generatedProfile:
                lut = GeneratedLUTFactory.make(profile: context.profile, dimension: recipe.dimension)
            case .cubeFile(let path):
                lut = try CubeLUTParser.parse(url: URL(fileURLWithPath: path))
            }

            let transformed = current.applyingFilterIfAvailable("CIColorCubeWithColorSpace", parameters: [
                "inputCubeDimension": lut.dimension,
                "inputCubeData": lut.data,
                "inputColorSpace": context.workingColorSpace
            ])
            return mix(current, with: transformed, amount: recipe.strength * context.adjustments.intensity)
        }
    }
}

struct BaseColorStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.color
        let intensity = context.adjustments.intensity
        var output = image

        output = output.applyingFilterIfAvailable("CIColorControls", parameters: [
            kCIInputSaturationKey: 1 + ((recipe.saturation - 1) * intensity),
            kCIInputBrightnessKey: recipe.brightness * intensity,
            kCIInputContrastKey: 1 + ((recipe.contrast - 1) * intensity)
        ])

        output = output.applyingFilterIfAvailable("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1 + ((recipe.redBias - 1) * intensity), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1 + ((recipe.greenBias - 1) * intensity), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1 + ((recipe.blueBias - 1) * intensity), w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: 0.015 * recipe.temperature * intensity, y: 0.008 * recipe.tint * intensity, z: -0.012 * recipe.temperature * intensity, w: 0)
        ])

        if recipe.monochrome {
            output = output.applyingFilterIfAvailable("CIPhotoEffectMono", parameters: [:])
            let warm = constantColorImage(red: 0.18, green: 0.12, blue: 0.07, alpha: 1, extent: output.extent)
            output = warm.applyingFilterIfAvailable("CISoftLightBlendMode", parameters: [
                "inputBackgroundImage": output
            ])
        }

        if context.adjustments.fade > 0 {
            let faded = output.applyingFilterIfAvailable("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0.08 + context.adjustments.fade * 0.18),
                "inputPoint1": CIVector(x: 0.25, y: 0.28),
                "inputPoint2": CIVector(x: 0.5, y: 0.52),
                "inputPoint3": CIVector(x: 0.75, y: 0.78),
                "inputPoint4": CIVector(x: 1, y: 0.96)
            ])
            output = mix(output, with: faded, amount: context.adjustments.fade)
        }

        return mix(image, with: output, amount: intensity)
    }
}

struct SplitToneStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.color
        let intensity = context.adjustments.intensity
        guard intensity > 0.001 else { return image }

        var output = image

        let cmyOutput = output.applyingFilterIfAvailable("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1 + recipe.cyanShift * -0.10 * intensity, y: 0, z: recipe.magentaShift * 0.025 * intensity, w: 0),
            "inputGVector": CIVector(x: recipe.cyanShift * 0.02 * intensity, y: 1 + recipe.magentaShift * -0.10 * intensity, z: recipe.yellowShift * 0.02 * intensity, w: 0),
            "inputBVector": CIVector(x: recipe.cyanShift * 0.02 * intensity, y: recipe.magentaShift * 0.025 * intensity, z: 1 + recipe.yellowShift * -0.10 * intensity, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: recipe.cyanShift * -0.01 * intensity, y: recipe.magentaShift * -0.006 * intensity, z: recipe.yellowShift * -0.012 * intensity, w: 0)
        ])
        output = mix(output, with: cmyOutput, amount: min(abs(recipe.cyanShift) + abs(recipe.magentaShift) + abs(recipe.yellowShift), 1) * 0.65)

        let shadowStrength = min(abs(recipe.shadowRed) + abs(recipe.shadowGreen) + abs(recipe.shadowBlue), 1)
        if shadowStrength > 0.001 {
            let shadowTint = constantColorImage(
                red: 0.5 + recipe.shadowRed * 0.5,
                green: 0.5 + recipe.shadowGreen * 0.5,
                blue: 0.5 + recipe.shadowBlue * 0.5,
                alpha: min(0.28 * shadowStrength * intensity, 0.45),
                extent: output.extent
            )
            output = shadowTint.applyingFilterIfAvailable("CIMultiplyBlendMode", parameters: [
                "inputBackgroundImage": output
            ]).cropped(to: output.extent)
        }

        let highlightStrength = min(abs(recipe.highlightRed) + abs(recipe.highlightGreen) + abs(recipe.highlightBlue), 1)
        if highlightStrength > 0.001 {
            let highlightTint = constantColorImage(
                red: 0.5 + recipe.highlightRed * 0.5,
                green: 0.5 + recipe.highlightGreen * 0.5,
                blue: 0.5 + recipe.highlightBlue * 0.5,
                alpha: min(0.22 * highlightStrength * intensity, 0.4),
                extent: output.extent
            )
            output = highlightTint.applyingFilterIfAvailable("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": output
            ]).cropped(to: output.extent)
        }

        return output
    }
}

struct FilmicResponseStage: CustomCIKernelStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        guard let kernel = FilmKernelLibrary.filmicResponse else { return image }
        let tone = context.profile.recipe.tone
        let toe = 0.82 + max(0, tone.p0.y) * 0.9 + context.adjustments.fade * 0.28
        let shoulder = 1.15 + max(0, 1 - tone.p4.y) * 1.9 + context.profile.recipe.bloom.amount * 0.65
        let lift = max(0, tone.p0.y) * 0.035 + context.adjustments.fade * 0.025
        let intensity = min(0.65, context.adjustments.intensity * 0.42)
        return kernel
            .apply(extent: image.extent, arguments: [image, toe, shoulder, lift, intensity])?
            .cropped(to: image.extent) ?? image
    }
}

struct ToneCurveStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let tone = context.profile.recipe.tone
        let output = image.applyingFilterIfAvailable("CIToneCurve", parameters: [
            "inputPoint0": CIVector(cgPoint: tone.p0),
            "inputPoint1": CIVector(cgPoint: tone.p1),
            "inputPoint2": CIVector(cgPoint: tone.p2),
            "inputPoint3": CIVector(cgPoint: tone.p3),
            "inputPoint4": CIVector(cgPoint: tone.p4)
        ])
        return mix(image, with: output, amount: context.adjustments.intensity)
    }
}

struct BloomStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.bloom
        let amount = recipe.amount * context.adjustments.bloom * context.adjustments.intensity
        guard amount > 0.001 else { return image }
        let extent = image.extent
        let highlights = image
            .applyingFilterIfAvailable("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: -0.36,
                kCIInputContrastKey: 5.4
            ])
            .cropped(to: extent)

        let radii = [recipe.radius * 0.38, recipe.radius, recipe.radius * 2.1]
        let weights = [0.34, 0.43, 0.23]
        var bloom = constantColorImage(red: 0, green: 0, blue: 0, alpha: 1, extent: extent)
        for (index, radius) in radii.enumerated() {
            let pass = highlights
                .applyingFilterIfAvailable("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(0.5, radius)])
                .cropped(to: extent)
                .applyingFilterIfAvailable("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: amount * weights[index]),
                    "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
                ])
            bloom = pass.applyingFilterIfAvailable("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": bloom
            ]).cropped(to: extent)
        }

        return bloom.applyingFilterIfAvailable("CIScreenBlendMode", parameters: [
            "inputBackgroundImage": image
        ]).cropped(to: extent)
    }
}

struct HalationStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.halation
        let amount = recipe.amount * context.adjustments.halation * context.adjustments.intensity
        guard amount > 0.001 else { return image }

        let extent = image.extent
        let highlights = image
            .applyingFilterIfAvailable("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: -0.48,
                kCIInputContrastKey: 6.5
            ])
            .cropped(to: extent)

        let edges = image
            .applyingFilterIfAvailable("CIEdges", parameters: [kCIInputIntensityKey: 1.7])
            .applyingFilterIfAvailable("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: -0.08,
                kCIInputContrastKey: 2.4
            ])
            .cropped(to: extent)

        let mask = highlights
            .applyingFilterIfAvailable("CIMultiplyBlendMode", parameters: ["inputBackgroundImage": edges])
            .applyingFilterIfAvailable("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: recipe.radius
            ])
            .cropped(to: extent)

        let warmth = recipe.warmth
        let glow = mask.applyingFilterIfAvailable("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.0 + warmth * 0.65, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.35 + warmth * 0.12, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.12, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: min(amount * 1.2, 0.85)),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        return glow.applyingFilterIfAvailable("CIScreenBlendMode", parameters: [
            "inputBackgroundImage": image
        ]).cropped(to: extent)
    }
}

struct LensStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let lens = context.profile.recipe.lens
        var output = image
        let extent = image.extent
        let center = CIVector(x: extent.midX, y: extent.midY)
        let base = min(extent.width, extent.height)

        if lens.edgeSoftness > 0.001 {
            let softened = image.applyingFilterIfAvailable("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 1.2 + lens.edgeSoftness * 4.5 * context.adjustments.softness
            ])
            let mask = radialEdgeMask(extent: extent, inner: base * 0.34, outer: base * 0.72)
            output = softened.applyingFilterIfAvailable("CIBlendWithMask", parameters: [
                "inputBackgroundImage": output,
                "inputMaskImage": mask
            ]).cropped(to: extent)
        }

        let softness = lens.softness * context.adjustments.softness * context.adjustments.intensity
        if softness > 0.001 {
            let blur = image.applyingFilterIfAvailable("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 0.8 + softness * 3.5
            ])
            output = mix(output, with: blur, amount: min(softness, 0.55))
        }

        if lens.sharpen > 0.001 {
            output = output.applyingFilterIfAvailable("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: lens.sharpen
            ])
        }

        if lens.downsample < 0.82 || lens.edgeSoftness > 0.18 {
            output = output.applyingFilterIfAvailable("CIBumpDistortion", parameters: [
                kCIInputCenterKey: center,
                kCIInputRadiusKey: base * 0.78,
                kCIInputScaleKey: -18 * max(0.08, lens.edgeSoftness)
            ]).cropped(to: extent)
        }

        return output.cropped(to: extent)
    }
}

struct ChromaticAberrationStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let amount = context.profile.recipe.aberration.amount * context.adjustments.intensity
        guard amount > 0.001 else { return image }
        let extent = image.extent
        let base = min(extent.width, extent.height)
        let edgeMask = radialEdgeMask(extent: extent, inner: base * 0.28, outer: base * 0.66)
        let red = image
            .transformed(by: CGAffineTransform(translationX: amount * 1.2, y: 0))
            .applyingFilterIfAvailable("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.18),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ])
        let cyan = image
            .transformed(by: CGAffineTransform(translationX: -amount, y: 0))
            .applyingFilterIfAvailable("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0.7, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.9, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.14),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ])

        let first = red.applyingFilterIfAvailable("CIScreenBlendMode", parameters: ["inputBackgroundImage": image])
        let aberrated = cyan.applyingFilterIfAvailable("CIScreenBlendMode", parameters: ["inputBackgroundImage": first]).cropped(to: extent)
        return aberrated.applyingFilterIfAvailable("CIBlendWithMask", parameters: [
            "inputBackgroundImage": image,
            "inputMaskImage": edgeMask
        ]).cropped(to: extent)
    }
}

struct VignetteStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.vignette
        let amount = recipe.amount * context.adjustments.vignette * context.adjustments.intensity
        guard amount > 0.001 else { return image }
        return image.applyingFilterIfAvailable("CIVignette", parameters: [
            kCIInputIntensityKey: amount,
            kCIInputRadiusKey: recipe.radius
        ]).cropped(to: image.extent)
    }
}

struct GrainStage: PipelineStage {
    var backend: StageBackend { FilmKernelLibrary.filmGrain == nil ? .builtInCoreImage : .customCoreImageKernel }

    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.grain
        let amount = recipe.amount * context.adjustments.grain * context.adjustments.intensity
        guard amount > 0.001 else { return image }
        let extent = image.extent

        if let kernel = FilmKernelLibrary.filmGrain {
            let kernelAmount = min(amount * 0.22, 0.55)
            return kernel.apply(extent: extent, arguments: [
                image,
                kernelAmount,
                max(0.55, recipe.scale),
                recipe.monochrome ? 0 : 0.58,
                Float(context.renderSeed % 100_000) / 997.0,
                recipe.shadows,
                recipe.highlights
            ])?.cropped(to: extent) ?? image
        }

        guard let random = CIFilter(name: "CIRandomGenerator")?.outputImage?.cropped(to: extent) else { return image }

        var grain = random
        if recipe.monochrome {
            grain = grain.applyingFilterIfAvailable("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: -0.02,
                kCIInputContrastKey: 1.8 + recipe.scale
            ])
        } else {
            grain = grain.applyingFilterIfAvailable("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.8,
                kCIInputBrightnessKey: -0.03,
                kCIInputContrastKey: 2.4
            ])
        }

        let opacity = min(amount * 0.16, 0.42)
        grain = grain.applyingFilterIfAvailable("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: opacity),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        return grain.applyingFilterIfAvailable("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": image
        ]).cropped(to: extent)
    }
}

struct DustStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let recipe = context.profile.recipe.dust
        let amount = recipe.amount * context.adjustments.dust * context.adjustments.intensity
        guard amount > 0.001 else { return image }
        let extent = image.extent
        guard let random = CIFilter(name: "CIRandomGenerator")?.outputImage?.cropped(to: extent) else { return image }
        let dust = random
            .applyingFilterIfAvailable("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: 0.55,
                kCIInputContrastKey: 12 + amount * 10
            ])
            .applyingFilterIfAvailable("CIMorphologyMaximum", parameters: [
                kCIInputRadiusKey: 0.5 + amount * 0.8
            ])
            .applyingFilterIfAvailable("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: min(0.14 * amount, 0.35)),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ])

        return dust.applyingFilterIfAvailable("CIScreenBlendMode", parameters: [
            "inputBackgroundImage": image
        ]).cropped(to: extent)
    }
}

struct BorderStage: PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage {
        let border = context.profile.recipe.border
        guard context.adjustments.borderEnabled, border.style != .none, border.amount > 0 else { return image }
        let extent = image.extent.integral
        let base = min(extent.width, extent.height)
        let thin = max(16, base * 0.035 * border.amount)
        let bottomExtra = border.style == .instant ? thin * 2.8 : thin * 0.4
        let newExtent = CGRect(
            x: 0,
            y: 0,
            width: extent.width + thin * 2,
            height: extent.height + thin * 2 + bottomExtra
        )

        let paper: CIImage
        switch border.style {
        case .instant:
            paper = constantColorImage(red: 0.94, green: 0.91, blue: 0.84, alpha: 1, extent: newExtent)
        case .print, .halfFrame:
            paper = constantColorImage(red: 0.08, green: 0.075, blue: 0.065, alpha: 1, extent: newExtent)
        case .thin:
            paper = constantColorImage(red: 0.02, green: 0.02, blue: 0.022, alpha: 1, extent: newExtent)
        case .none:
            return image
        }

        let placed = image.transformed(by: CGAffineTransform(translationX: thin - extent.minX, y: thin + bottomExtra - extent.minY))
        return placed.applyingFilterIfAvailable("CISourceOverCompositing", parameters: [
            "inputBackgroundImage": paper
        ]).cropped(to: newExtent)
    }
}
