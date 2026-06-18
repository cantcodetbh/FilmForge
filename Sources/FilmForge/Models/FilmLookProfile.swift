import CoreImage
import Foundation
import SwiftUI

struct FilmLookProfile: Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var baseExposure: Double
    var contrast: Double
    var toeStrength: Double
    var shoulderStrength: Double
    var blackPoint: Double
    var whitePoint: Double
    var saturation: Double
    var vibrance: Double
    var colourTemperatureBias: Double
    var tintBias: Double
    var digitalTamingProfile: DigitalTamingProfile = .none
    var printProfile: PrintResponseProfile = .neutral
    var cameraResponseProfile: CameraResponseProfile = .neutral
    var lutName: String?
    var lutURL: URL?
    var lutIntensity: Double
    var grainProfile: GrainProfile
    var halationProfile: HalationProfile
    var bloomProfile: BloomProfile
    var vignetteProfile: VignetteProfile
    var lensProfile: LensProfile
    var dustProfile: DustProfile
    var dateStampProfile: DateStampProfile
    var randomnessProfile: RandomnessProfile = .none
    var filmFlatnessProfile: FilmFlatnessProfile = .none
    var labScanProfile: LabScanProfile = .none
    var pushPull: Double = 0
    var componentDefaults: LookComponentIntensities = .standard
}

struct LookComponentIntensities: Equatable {
    var tone: Double
    var colour: Double
    var lut: Double
    var grain: Double
    var glow: Double
    var lens: Double
    var artefacts: Double
    var softness: Double

    static let standard = LookComponentIntensities(
        tone: 1,
        colour: 1,
        lut: 1,
        grain: 1,
        glow: 1,
        lens: 1,
        artefacts: 1,
        softness: 1
    )

    func clamped() -> LookComponentIntensities {
        LookComponentIntensities(
            tone: clamp(tone),
            colour: clamp(colour),
            lut: clamp(lut),
            grain: clamp(grain),
            glow: clamp(glow),
            lens: clamp(lens),
            artefacts: clamp(artefacts),
            softness: clamp(softness)
        )
    }

    private func clamp(_ value: Double) -> Double {
        max(0, min(value, 1.5))
    }
}

struct DigitalTamingProfile: Equatable {
    var enabled: Bool
    var clarityReduction: Double
    var edgeHaloSuppression: Double
    var localHDRCompression: Double
    var preBlur: Double

    static let none = DigitalTamingProfile(
        enabled: false,
        clarityReduction: 0,
        edgeHaloSuppression: 0,
        localHDRCompression: 0,
        preBlur: 0
    )
}

struct PrintResponseProfile: Equatable {
    var highlightDesaturation: Double
    var highlightRolloff: Double
    var paperBlack: Double
    var paperWhite: Double

    static let neutral = PrintResponseProfile(
        highlightDesaturation: 0.34,
        highlightRolloff: 0.42,
        paperBlack: 0,
        paperWhite: 1
    )
}

struct CameraResponseProfile: Equatable {
    var enabled: Bool
    var colorSeparation: Double
    var crossProcess: Double
    var cyanShadow: Double
    var warmHighlight: Double
    var redChannelBloom: Double
    var greenBias: Double
    var blueBias: Double
    var dyeContamination: Double
    var scanFade: Double
    var cheapness: Double

    static let neutral = CameraResponseProfile(
        enabled: false,
        colorSeparation: 0,
        crossProcess: 0,
        cyanShadow: 0,
        warmHighlight: 0,
        redChannelBloom: 0,
        greenBias: 0,
        blueBias: 0,
        dyeContamination: 0,
        scanFade: 0,
        cheapness: 0
    )
}

struct GrainProfile: Equatable {
    var enabled: Bool
    var preset: GrainPreset
    var size: Double
    var roughness: Double
    var strength: Double
    var chromaAmount: Double
    var highlightBias: Double
    var shadowAmount: Double
    var midtoneAmount: Double
    var highlightAmount: Double
    var resolution: Double

    static let none = GrainProfile(
        enabled: false,
        preset: .fine50,
        size: 1,
        roughness: 0.35,
        strength: 0,
        chromaAmount: 0,
        highlightBias: 0.5,
        shadowAmount: 0,
        midtoneAmount: 0,
        highlightAmount: 0,
        resolution: 1
    )
}

enum GrainPreset: String, CaseIterable, Identifiable {
    case fine50 = "Fine 50"
    case medium250 = "Medium 250"
    case heavy500 = "Heavy 500"
    case disposableCompact = "Disposable Compact"

    var id: String { rawValue }
}

struct HalationProfile: Equatable {
    var enabled: Bool
    var intensity: Double
    var threshold: Double
    var radius: Double
    var tint: CIColor
    var blend: Double

    static let none = HalationProfile(enabled: false, intensity: 0, threshold: 0.78, radius: 14, tint: CIColor(red: 1, green: 0.32, blue: 0.12), blend: 0.6)
}

struct BloomProfile: Equatable {
    var enabled: Bool
    var threshold: Double
    var radius: Double
    var intensity: Double
    var softness: Double
    var blendMode: BloomBlendMode

    static let none = BloomProfile(enabled: false, threshold: 0.8, radius: 10, intensity: 0, softness: 0.5, blendMode: .screen)
}

enum BloomBlendMode: String, CaseIterable, Identifiable {
    case screen = "Screen"
    case add = "Add"
    case softLight = "Soft Light"

    var id: String { rawValue }
}

struct VignetteProfile: Equatable {
    var enabled: Bool
    var intensity: Double
    var radius: Double
    var softness: Double
    var centerX: Double = 0.5
    var centerY: Double = 0.5
    var blueBias: Double = 0

    static let none = VignetteProfile(enabled: false, intensity: 0, radius: 1.2, softness: 0.65)
}

struct LensProfile: Equatable {
    var enabled: Bool
    var chromaticAberration: Double
    var edgeSoftness: Double
    var compactBlur: Double
    var flashAmount: Double = 0
    var flashRadius: Double = 0.72
    var flashWarmth: Double = 0.18

    static let none = LensProfile(enabled: false, chromaticAberration: 0, edgeSoftness: 0, compactBlur: 0)
}

struct DustProfile: Equatable {
    var enabled: Bool
    var dustAmount: Double
    var scratchAmount: Double
    var lightLeakAmount: Double

    static let none = DustProfile(enabled: false, dustAmount: 0, scratchAmount: 0, lightLeakAmount: 0)
}

struct DateStampProfile: Equatable {
    var enabled: Bool
    var text: String
    var opacity: Double

    static let none = DateStampProfile(enabled: false, text: "", opacity: 0)
}

struct RandomnessProfile: Equatable {
    var enabled: Bool
    var lightLeakJitter: Double
    var dustJitter: Double
    var dateStampJitter: Double
    var flashJitter: Double

    static let none = RandomnessProfile(
        enabled: false,
        lightLeakJitter: 0,
        dustJitter: 0,
        dateStampJitter: 0,
        flashJitter: 0
    )
}

struct FilmFlatnessProfile: Equatable {
    var enabled: Bool
    var intensity: Double
    var frequency: Double

    static let none = FilmFlatnessProfile(enabled: false, intensity: 0, frequency: 1)
}

struct LabScanProfile: Equatable {
    var enabled: Bool
    var shadowColorShift: Double
    var scannerNoiseAmount: Double

    static let none = LabScanProfile(enabled: false, shadowColorShift: 0, scannerNoiseAmount: 0)
}

struct PipelineToggles: Equatable {
    var tone = true
    var lut = true
    var grain = true
    var halation = true
    var bloom = true
    var lens = true
    var artefacts = true
    var xpro = false
    var dustScratches = true
    var lightLeaks = true
    var labScan = true
    var dateStamp = true
}

struct ExportSettings: Equatable {
    var format: ExportFormat = .jpeg
    var jpegQuality: Double = 0.92
    var outputColorSpaceName: String = "sRGB"
    var lutOnly = false
    var renderSeed: Double = 0
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPEG"
    case png = "PNG"

    var id: String { rawValue }
    var fileExtension: String { self == .jpeg ? "jpg" : "png" }
    var uniformTypeIdentifier: String { self == .jpeg ? "public.jpeg" : "public.png" }
}
