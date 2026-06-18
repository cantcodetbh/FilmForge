import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

struct LUTCube {
    var dimension: Int
    var data: Data
    var colorSpace: CGColorSpace
}

struct LUTLoader {
    private var cubeParser = CubeLUTParser()
    private var haldLoader = HaldCLUTLoader()

    func loadCube(name: String?, url: URL?, fallbackProfileID: String) -> LUTCube {
        if let url {
            if url.pathExtension.lowercased() == "cube", let cube = try? cubeParser.parse(url: url) {
                return cube
            }
            if ["png", "tif", "tiff"].contains(url.pathExtension.lowercased()), let cube = try? haldLoader.load(url: url) {
                return cube
            }
        }

        return Self.makeCreativeCube(named: name ?? fallbackProfileID)
    }

    func apply(cube: LUTCube, to image: CIImage) -> CIImage? {
        let filter = CIFilter.colorCubeWithColorSpace()
        filter.inputImage = image
        filter.cubeDimension = Float(cube.dimension)
        filter.cubeData = cube.data
        filter.colorSpace = cube.colorSpace
        return filter.outputImage
    }

    static let blendKernel = CIColorKernel(source: """
    kernel vec4 blendLUT(__sample a, __sample b, float amount) {
        return mix(a, b, clamp(amount, 0.0, 1.0));
    }
    """)!

    static func makeCreativeCube(named name: String) -> LUTCube {
        let dimension = 32
        var floats = [Float]()
        floats.reserveCapacity(dimension * dimension * dimension * 4)

        for b in 0..<dimension {
            for g in 0..<dimension {
                for r in 0..<dimension {
                    var red = Float(r) / Float(dimension - 1)
                    var green = Float(g) / Float(dimension - 1)
                    var blue = Float(b) / Float(dimension - 1)
                    let luma = red * 0.2126 + green * 0.7152 + blue * 0.0722
                    let shadow = 1 - smoothstep(0.12, 0.55, luma)
                    let highlight = smoothstep(0.58, 0.96, luma)
                    let mid = smoothstep(0.16, 0.48, luma) * (1 - smoothstep(0.62, 0.92, luma))

                    switch name {
                    case "classic-negative":
                        red = density(red, toe: 0.06, shoulder: 0.18) * 1.02 + highlight * 0.010
                        green = density(green, toe: 0.09, shoulder: 0.17) * (0.98 + 0.03 * mid)
                        blue = density(blue, toe: 0.04, shoulder: 0.12) * 0.95 + shadow * 0.020
                        green -= shadow * 0.020
                    case "warm-disposable":
                        red = density(red, toe: 0.05, shoulder: 0.30) * 1.10 + 0.025
                        green = density(green, toe: 0.05, shoulder: 0.20) * 1.01 + highlight * 0.012
                        blue = density(blue, toe: 0.13, shoulder: 0.12) * 0.84 + shadow * 0.006
                        red += shadow * 0.018
                    case "disposable-flash":
                        red = density(red, toe: 0.08, shoulder: 0.34) * 1.06 + highlight * 0.020
                        green = density(green, toe: 0.08, shoulder: 0.24) * 0.99 + mid * 0.008
                        blue = density(blue, toe: 0.14, shoulder: 0.18) * 0.88 + shadow * 0.012
                        red += shadow * 0.012
                        green -= shadow * 0.006
                    case "huji-1998", "huji-flash-leak":
                        red = density(red, toe: 0.04, shoulder: 0.42) * 1.13 + highlight * 0.030 + shadow * 0.012
                        green = density(green, toe: 0.07, shoulder: 0.24) * 0.98 + mid * 0.010
                        blue = density(blue, toe: 0.16, shoulder: 0.16) * 0.82 + shadow * 0.008
                        red += mid * 0.014
                        blue -= highlight * 0.016
                    case "kodak-funsaver-800":
                        red = density(red, toe: 0.07, shoulder: 0.38) * 1.08 + highlight * 0.026
                        green = density(green, toe: 0.07, shoulder: 0.26) * 1.00 + mid * 0.006
                        blue = density(blue, toe: 0.15, shoulder: 0.18) * 0.86 + shadow * 0.010
                        red += shadow * 0.010
                        green -= shadow * 0.004
                    case "fuji-quicksnap-400":
                        red = density(red, toe: 0.10, shoulder: 0.24) * 0.94 + highlight * 0.008
                        green = density(green, toe: 0.08, shoulder: 0.18) * 1.03 + mid * 0.006
                        blue = density(blue, toe: 0.06, shoulder: 0.22) * 1.08 + shadow * 0.018
                        red -= shadow * 0.006
                    case "dazz-d-exp":
                        red = positive(red, contrast: 1.16, saturationLift: 0.016) + highlight * 0.014
                        green = positive(green, contrast: 1.10, saturationLift: 0.004)
                        blue = positive(blue, contrast: 1.08, saturationLift: 0.006) + shadow * 0.010
                        red += mid * 0.012
                        blue -= highlight * 0.010
                    case "dazz-cpm35":
                        red = pow(red, 0.88) * 1.015 + highlight * 0.018
                        green = pow(green, 0.94) * 1.010
                        blue = pow(blue, 0.90) * 1.020 + shadow * 0.010
                        let gray = (red + green + blue) / 3
                        red = gray + (red - gray) * 0.72
                        green = gray + (green - gray) * 0.72
                        blue = gray + (blue - gray) * 0.72
                    case "dazz-classic":
                        red = density(red, toe: 0.12, shoulder: 0.28) * 1.04 + highlight * 0.018
                        green = density(green, toe: 0.12, shoulder: 0.22) * 0.99
                        blue = density(blue, toe: 0.14, shoulder: 0.18) * 0.94 + shadow * 0.012
                        red += mid * 0.008
                    case "motion-picture-500t":
                        red = density(red, toe: 0.06, shoulder: 0.34) * (1.02 + 0.04 * highlight)
                        green = density(green, toe: 0.08, shoulder: 0.22) * 0.98
                        blue = density(blue, toe: 0.03, shoulder: 0.18) * 1.08 + shadow * 0.018
                        red += highlight * 0.018
                        green -= shadow * 0.010
                    case "soft-pastel-400":
                        red = pow(red, 0.92) * 1.02
                        green = pow(green, 0.96) * 1.02
                        blue = pow(blue, 0.90) * 1.03
                        let gray = (red + green + blue) / 3
                        red = gray + (red - gray) * 0.82
                        green = gray + (green - gray) * 0.82
                        blue = gray + (blue - gray) * 0.82
                        red += highlight * 0.020
                        blue += shadow * 0.016
                    case "faded-print", "faded-lab-print":
                        red = density(red, toe: 0.22, shoulder: 0.30) * 1.06 + 0.040
                        green = density(green, toe: 0.24, shoulder: 0.30) * 0.96 + 0.025
                        blue = density(blue, toe: 0.32, shoulder: 0.22) * 0.82 + 0.018
                    case "slide-chrome":
                        red = positive(red, contrast: 1.20, saturationLift: 0.018)
                        green = positive(green, contrast: 1.18, saturationLift: 0.008)
                        blue = positive(blue, contrast: 1.16, saturationLift: 0.014)
                        red += mid * 0.010
                        blue += shadow * 0.010
                    case "silver-gelatin":
                        let warmGray = pow(luma, 0.92)
                        red = warmGray * 1.025
                        green = warmGray * 1.005
                        blue = warmGray * 0.955
                        red += shadow * 0.010
                    case "night-tungsten":
                        red = density(red, toe: 0.12, shoulder: 0.42) * 1.04 + highlight * 0.030
                        green = density(green, toe: 0.11, shoulder: 0.26) * 0.92
                        blue = density(blue, toe: 0.03, shoulder: 0.18) * 1.12 + shadow * 0.030
                    case "high-key-portrait":
                        red = density(red, toe: 0.18, shoulder: 0.46) * 1.035 + highlight * 0.020
                        green = density(green, toe: 0.16, shoulder: 0.42) * 1.005
                        blue = density(blue, toe: 0.19, shoulder: 0.34) * 0.94 + shadow * 0.010
                        let gray = (red + green + blue) / 3
                        red = gray + (red - gray) * 0.88
                        green = gray + (green - gray) * 0.88
                        blue = gray + (blue - gray) * 0.88
                    case "matte-archive":
                        red = density(red, toe: 0.36, shoulder: 0.30) * 1.08 + 0.060
                        green = density(green, toe: 0.34, shoulder: 0.28) * 0.96 + 0.040
                        blue = density(blue, toe: 0.42, shoulder: 0.20) * 0.76 + 0.030
                    case "coastal-print":
                        red = density(red, toe: 0.12, shoulder: 0.22) * 0.96 + highlight * 0.018
                        green = density(green, toe: 0.10, shoulder: 0.18) * 1.02
                        blue = density(blue, toe: 0.06, shoulder: 0.24) * 1.06 + shadow * 0.016
                    default:
                        break
                    }

                    let compressed = compressHighlights(red: red, green: green, blue: blue)
                    red = compressed.0
                    green = compressed.1
                    blue = compressed.2

                    floats.append(min(max(red, 0), 1))
                    floats.append(min(max(green, 0), 1))
                    floats.append(min(max(blue, 0), 1))
                    floats.append(1)
                }
            }
        }

        return LUTCube(
            dimension: dimension,
            data: Data(bytes: floats, count: floats.count * MemoryLayout<Float>.size),
            colorSpace: RenderContext.outputColorSpace
        )
    }

    private static func density(_ value: Float, toe: Float, shoulder: Float) -> Float {
        let lifted = max(0, (value + toe) / (1 + toe))
        return 1 - exp(-lifted * (1.0 + shoulder * 2.5))
    }

    private static func positive(_ value: Float, contrast: Float, saturationLift: Float) -> Float {
        let pivoted = (value - 0.5) * contrast + 0.5
        return pow(max(0, pivoted), 0.92) + saturationLift
    }

    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / max(edge1 - edge0, 0.0001), 0), 1)
        return t * t * (3 - 2 * t)
    }

    private static func compressHighlights(red: Float, green: Float, blue: Float) -> (Float, Float, Float) {
        let mx = max(red, max(green, blue))
        let roll = smoothstep(0.82, 1.12, mx)
        let white = min(max(mx, 0), 1)
        return (
            red * (1 - roll * 0.18) + white * roll * 0.18,
            green * (1 - roll * 0.18) + white * roll * 0.18,
            blue * (1 - roll * 0.18) + white * roll * 0.18
        )
    }
}
