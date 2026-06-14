import CoreGraphics
import CoreImage
import Foundation

struct FilmProfile: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let tagline: String
    let description: String
    let cameraName: String
    let filmName: String
    let accent: ProfileAccent
    let recipe: FilmRecipe
    let defaultAdjustments: UserAdjustments
}

struct CameraProfile: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let reference: String
    let format: CaptureFormat
    let tagline: String
    let description: String
    let accent: ProfileAccent
    let recipe: FilmRecipe
}

enum FilmRecipeBehavior: Hashable, Sendable {
    case composeWithCamera
    case completeProfile
}

struct FilmStock: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let reference: String
    let family: FilmFamily
    let tagline: String
    let description: String
    let accent: ProfileAccent
    let recipe: FilmRecipe
    var behavior: FilmRecipeBehavior = .composeWithCamera
}

enum CaptureFormat: String, CaseIterable, Hashable, Sendable {
    case thirtyFive = "135"
    case medium120 = "120"
    case halfFrame = "Half-frame"
    case instant = "Instant"
    case toy = "Toy"
    case disposable = "Disposable"
    case ccd = "CCD"
}

enum FilmFamily: String, CaseIterable, Hashable, Sendable {
    case colorNegative = "Color negative"
    case slide = "Slide"
    case blackAndWhite = "Black and white"
    case instant = "Instant"
    case digitalSensor = "Digital sensor"
}

struct ProfileAccent: Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
}

struct FilmRecipe: Hashable, Sendable {
    var capture: CaptureRecipe = .neutral
    var filmResponse: FilmResponseRecipe = .neutral
    var print: PrintRecipe = .neutral
    var color: ColorRecipe
    var luts: [LUTRecipe] = []
    var tone: ToneCurveRecipe
    var grain: GrainRecipe
    var bloom: BloomRecipe
    var halation: HalationRecipe
    var vignette: VignetteRecipe
    var lens: LensRecipe
    var output: OutputRecipe = .neutral
    var aberration: AberrationRecipe
    var dust: DustRecipe
    var border: BorderRecipe
}

struct LUTRecipe: Hashable, Sendable {
    enum Source: Hashable, Sendable {
        case generatedProfile
        case cubeFile(String)
    }

    var id: String
    var source: Source
    var dimension: Int
    var strength: Double
}

struct CaptureRecipe: Hashable, Sendable {
    enum SourceMode: String, Hashable, Sendable {
        case neutral
        case heifProcessed
        case rawNatural
        case ccdJpeg
        case instant
        case toy
    }

    var sourceMode: SourceMode
    var dynamicRange: Double
    var sensorClip: Double
    var phoneHDRSuppression: Double
    var inputSharpening: Double
    var noiseFloor: Double
    var whiteBalanceBias: Double

    static let neutral = CaptureRecipe(
        sourceMode: .neutral,
        dynamicRange: 1,
        sensorClip: 0,
        phoneHDRSuppression: 0,
        inputSharpening: 0,
        noiseFloor: 0,
        whiteBalanceBias: 0
    )
}

struct FilmResponseRecipe: Hashable, Sendable {
    struct ExposureState: Hashable, Sendable {
        var contrast: Double
        var saturation: Double
        var red: Double
        var green: Double
        var blue: Double
        var shadowLift: Double
        var highlightCompression: Double
        var density: Double
    }

    var enabled: Bool
    var under: ExposureState
    var normal: ExposureState
    var over: ExposureState
    var lumaStrength: Double
    var chromaStrength: Double
    var densityStrength: Double

    static let neutralState = ExposureState(
        contrast: 1,
        saturation: 1,
        red: 1,
        green: 1,
        blue: 1,
        shadowLift: 0,
        highlightCompression: 0,
        density: 0
    )

    static let neutral = FilmResponseRecipe(
        enabled: false,
        under: neutralState,
        normal: neutralState,
        over: neutralState,
        lumaStrength: 0,
        chromaStrength: 0,
        densityStrength: 0
    )
}

struct PrintRecipe: Hashable, Sendable {
    enum Medium: String, Hashable, Sendable {
        case none
        case minilab
        case opticalPrint
        case slideProjection
        case instantChemistry
        case ccdProcessor
        case cheapScan
    }

    var medium: Medium
    var contrast: Double
    var saturation: Double
    var blackPoint: Double
    var whitePoint: Double
    var cyan: Double
    var magenta: Double
    var yellow: Double
    var highlightWarmth: Double
    var paperTint: Double

    static let neutral = PrintRecipe(
        medium: .none,
        contrast: 1,
        saturation: 1,
        blackPoint: 0,
        whitePoint: 1,
        cyan: 0,
        magenta: 0,
        yellow: 0,
        highlightWarmth: 0,
        paperTint: 0
    )
}

struct ColourManagedImage: @unchecked Sendable {
    let url: URL
    let ciImage: CIImage
    let displayName: String
    let pixelSize: CGSize
    let sourceColorSpace: CGColorSpace
    let workingColorSpace: CGColorSpace
    let outputColorSpace: CGColorSpace
    let profileName: String
    let metadata: [String: Any]

    var cacheIdentifier: String {
        "\(url.path)|\(Int(pixelSize.width))x\(Int(pixelSize.height))|\(profileName)"
    }
}

typealias ImportedImage = ColourManagedImage

struct UserAdjustments: Hashable, Sendable {
    var intensity: Double = 1
    var exposure: Double = 0
    var temperature: Double = 0
    var tint: Double = 0
    var grain: Double = 1
    var bloom: Double = 1
    var halation: Double = 1
    var vignette: Double = 1
    var fade: Double = 0
    var softness: Double = 1
    var dust: Double = 1
    var borderEnabled: Bool = true

    static let neutral = UserAdjustments()
}

struct ColorRecipe: Hashable, Sendable {
    var exposure: Double
    var brightness: Double
    var contrast: Double
    var saturation: Double
    var temperature: Double
    var tint: Double
    var redBias: Double
    var greenBias: Double
    var blueBias: Double
    var shadowRed: Double = 0
    var shadowGreen: Double = 0
    var shadowBlue: Double = 0
    var highlightRed: Double = 0
    var highlightGreen: Double = 0
    var highlightBlue: Double = 0
    var cyanShift: Double = 0
    var magentaShift: Double = 0
    var yellowShift: Double = 0
    var monochrome: Bool = false
}

struct ToneCurveRecipe: Hashable, Sendable {
    var p0: CGPoint
    var p1: CGPoint
    var p2: CGPoint
    var p3: CGPoint
    var p4: CGPoint
}

struct GrainRecipe: Hashable, Sendable {
    var amount: Double
    var scale: Double
    var monochrome: Bool
    var shadows: Double
    var highlights: Double
}

struct BloomRecipe: Hashable, Sendable {
    var amount: Double
    var radius: Double
}

struct HalationRecipe: Hashable, Sendable {
    var amount: Double
    var radius: Double
    var warmth: Double
}

struct VignetteRecipe: Hashable, Sendable {
    var amount: Double
    var radius: Double
    var softness: Double
}

struct LensRecipe: Hashable, Sendable {
    var softness: Double
    var edgeSoftness: Double
    var sharpen: Double
    var downsample: Double
    var fisheye: FisheyeRecipe = .none
}

struct FisheyeRecipe: Hashable, Sendable {
    enum Projection: String, Hashable, Sendable {
        case none
        case diagonal
        case circular
        case croppedCircular
    }

    var projection: Projection
    var strength: Double
    var fieldOfView: Double
    var imageCircle: Double
    var edgeDarkness: Double
    var edgeBlur: Double
    var chromaticEdge: Double
    var circleFeather: Double

    static let none = FisheyeRecipe(
        projection: .none,
        strength: 0,
        fieldOfView: 0,
        imageCircle: 1,
        edgeDarkness: 0,
        edgeBlur: 0,
        chromaticEdge: 0,
        circleFeather: 0
    )

    static func diagonal(
        strength: Double = 0.82,
        fieldOfView: Double = 165,
        edgeDarkness: Double = 0.55,
        edgeBlur: Double = 0.18,
        chromaticEdge: Double = 0.45
    ) -> FisheyeRecipe {
        FisheyeRecipe(
            projection: .diagonal,
            strength: strength,
            fieldOfView: fieldOfView,
            imageCircle: 1.18,
            edgeDarkness: edgeDarkness,
            edgeBlur: edgeBlur,
            chromaticEdge: chromaticEdge,
            circleFeather: 0.08
        )
    }

    static func circular(
        cropped: Bool,
        strength: Double = 1,
        fieldOfView: Double = 180,
        imageCircle: Double = 0.94,
        edgeDarkness: Double = 0.85,
        edgeBlur: Double = 0.35,
        chromaticEdge: Double = 0.65
    ) -> FisheyeRecipe {
        FisheyeRecipe(
            projection: cropped ? .croppedCircular : .circular,
            strength: strength,
            fieldOfView: fieldOfView,
            imageCircle: imageCircle,
            edgeDarkness: edgeDarkness,
            edgeBlur: edgeBlur,
            chromaticEdge: chromaticEdge,
            circleFeather: 0.055
        )
    }
}

struct OutputRecipe: Hashable, Sendable {
    enum Aspect: String, Hashable, Sendable {
        case original
        case threeByTwo
        case square
        case halfFrame
        case instant
    }

    enum Palette: String, Hashable, Sendable {
        case natural
        case gameBoyGreen
        case hardMono
        case thermal
    }

    var aspect: Aspect = .original
    var palette: Palette = .natural
    var posterizeLevels: Double = 0
    var dateStamp: Bool = false
    var flashFalloff: Double = 0
    var labControlsEnabled: Bool = false
    var jpegCrunch: Double = 0
    var chromaBleed: Double = 0
    var lightLeak: Double = 0
    var scanlines: Double = 0

    static let neutral = OutputRecipe()
}

struct AberrationRecipe: Hashable, Sendable {
    var amount: Double
}

struct DustRecipe: Hashable, Sendable {
    var amount: Double
    var scratches: Double
}

struct BorderRecipe: Hashable, Sendable {
    enum Style: String, Hashable, Sendable {
        case none
        case thin
        case instant
        case print
        case halfFrame
    }

    var style: Style
    var amount: Double
}

extension FilmRecipe {
    static let neutral = FilmRecipe(
        capture: .neutral,
        filmResponse: .neutral,
        print: .neutral,
        color: ColorRecipe(
            exposure: 0,
            brightness: 0,
            contrast: 1,
            saturation: 1,
            temperature: 0,
            tint: 0,
            redBias: 1,
            greenBias: 1,
            blueBias: 1
        ),
        luts: [],
        tone: ToneCurveRecipe(
            p0: CGPoint(x: 0, y: 0),
            p1: CGPoint(x: 0.25, y: 0.25),
            p2: CGPoint(x: 0.5, y: 0.5),
            p3: CGPoint(x: 0.75, y: 0.75),
            p4: CGPoint(x: 1, y: 1)
        ),
        grain: GrainRecipe(amount: 0, scale: 1, monochrome: true, shadows: 0.6, highlights: 0.5),
        bloom: BloomRecipe(amount: 0, radius: 8),
        halation: HalationRecipe(amount: 0, radius: 8, warmth: 1),
        vignette: VignetteRecipe(amount: 0, radius: 1, softness: 0.5),
        lens: LensRecipe(softness: 0, edgeSoftness: 0, sharpen: 0, downsample: 1),
        output: .neutral,
        aberration: AberrationRecipe(amount: 0),
        dust: DustRecipe(amount: 0, scratches: 0),
        border: BorderRecipe(style: .none, amount: 0)
    )
}
