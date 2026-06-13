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

struct FilmStock: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let reference: String
    let family: FilmFamily
    let tagline: String
    let description: String
    let accent: ProfileAccent
    let recipe: FilmRecipe
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
    var color: ColorRecipe
    var luts: [LUTRecipe] = []
    var tone: ToneCurveRecipe
    var grain: GrainRecipe
    var bloom: BloomRecipe
    var halation: HalationRecipe
    var vignette: VignetteRecipe
    var lens: LensRecipe
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
        aberration: AberrationRecipe(amount: 0),
        dust: DustRecipe(amount: 0, scratches: 0),
        border: BorderRecipe(style: .none, amount: 0)
    )
}
