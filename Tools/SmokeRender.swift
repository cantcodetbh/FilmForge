import AppKit
import CoreImage
import Foundation

@main
struct SmokeRender {
    static func main() throws {
        let renderer = PreviewRenderer()
        print("Metal kernels active: \(FilmKernelLibrary.usesMetalKernels)")
        let extent = CGRect(x: 0, y: 0, width: 256, height: 192)
        let gradient = CIFilter(name: "CILinearGradient")!
        gradient.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
        gradient.setValue(CIVector(x: extent.width, y: extent.height), forKey: "inputPoint1")
        gradient.setValue(CIColor(red: 0.05, green: 0.08, blue: 0.12), forKey: "inputColor0")
        gradient.setValue(CIColor(red: 0.95, green: 0.82, blue: 0.58), forKey: "inputColor1")
        let source = gradient.outputImage!.cropped(to: extent)

        var count = 0
        for camera in ProfileCatalog.cameras {
            for film in ProfileCatalog.compatibleFilms(for: camera) {
                let profile = ProfileCatalog.makeProfile(camera: camera, film: film)
                _ = try renderer.renderPreview(
                    source: source,
                    profile: profile,
                    adjustments: profile.defaultAdjustments,
                    maxLongEdge: 256
                )
                count += 1
            }
        }

        print("Rendered \(count) camera/film combinations.")
    }
}
