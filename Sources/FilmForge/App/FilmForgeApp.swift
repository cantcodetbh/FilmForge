import SwiftUI
import CoreImage
import Darwin
import Foundation

@main
struct FilmForgeApp: App {
    init() {
        if CommandLine.arguments.contains("--smoke-render") {
            SmokeRender.run()
            exit(0)
        }
        if let index = CommandLine.arguments.firstIndex(of: "--analyze-references") {
            ReferenceAnalyzer.run(arguments: Array(CommandLine.arguments.suffix(from: index)))
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

private enum SmokeRender {
    static func run() {
        let gradient = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0, y: 0),
            "inputPoint1": CIVector(x: 640, y: 420),
            "inputColor0": CIColor(red: 0.02, green: 0.03, blue: 0.05),
            "inputColor1": CIColor(red: 1.0, green: 0.86, blue: 0.68)
        ])?.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 640, height: 420)) ?? CIImage.empty()

        let pipeline = FilmPipeline()
        for profile in ProfileCatalog.presets {
            let output = pipeline.render(input: gradient, profile: profile, componentIntensities: profile.componentDefaults, toggles: PipelineToggles())
            guard RenderContext.shared.context.createCGImage(output, from: output.extent, format: .RGBA8, colorSpace: RenderContext.outputColorSpace) != nil else {
                fputs("Smoke render failed for \(profile.name)\n", stderr)
                exit(2)
            }
        }
        print("Smoke rendered \(ProfileCatalog.presets.count) profiles")
    }
}
