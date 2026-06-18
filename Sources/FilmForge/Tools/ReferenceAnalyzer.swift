import AppKit
import CoreGraphics
import CoreImage
import Foundation

struct ReferenceImageMetrics: Codable {
    var path: String
    var group: String
    var width: Int
    var height: Int
    var meanLuma: Double
    var medianLuma: Double
    var p10Luma: Double
    var p90Luma: Double
    var contrastSpan: Double
    var meanSaturation: Double
    var warmBias: Double
    var highlightPressure: Double
    var shadowPressure: Double
    var grainProxy: Double
    var edgeContrastRatio: Double
    var edgeWarmShift: Double
}

struct ReferenceGroupSummary: Codable {
    var group: String
    var count: Int
    var meanLuma: Double
    var contrastSpan: Double
    var meanSaturation: Double
    var warmBias: Double
    var highlightPressure: Double
    var shadowPressure: Double
    var grainProxy: Double
    var edgeContrastRatio: Double
    var edgeWarmShift: Double
}

enum ReferenceAnalyzer {
    static func run(arguments: [String]) {
        let root = URL(fileURLWithPath: arguments.dropFirst().first ?? "references/film-look", relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            .standardizedFileURL
        let outputDirectory = root
        let fileURLs = imageURLs(in: root)

        guard !fileURLs.isEmpty else {
            fputs("No reference images found in \(root.path)\n", stderr)
            exit(2)
        }

        let metrics = fileURLs.compactMap { analyze(url: $0, root: root) }
        let summaries = summarize(metrics)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let json = try encoder.encode(ReferenceReport(images: metrics, groups: summaries))
            try json.write(to: outputDirectory.appendingPathComponent("analysis.json"), options: .atomic)

            let markdown = renderMarkdown(root: root, metrics: metrics, summaries: summaries)
            try markdown.write(to: outputDirectory.appendingPathComponent("ANALYSIS.md"), atomically: true, encoding: .utf8)
        } catch {
            fputs("Reference analysis failed: \(error.localizedDescription)\n", stderr)
            exit(3)
        }

        print("Analyzed \(metrics.count) references")
        for summary in summaries {
            print("\(summary.group): n=\(summary.count) luma=\(summary.meanLuma.rounded3) sat=\(summary.meanSaturation.rounded3) contrast=\(summary.contrastSpan.rounded3) grain=\(summary.grainProxy.rounded3)")
        }
    }

    private static func imageURLs(in root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
        return enumerator
            .compactMap { $0 as? URL }
            .filter { ["jpg", "jpeg", "png", "webp"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.path < $1.path }
    }

    private static func analyze(url: URL, root: URL) -> ReferenceImageMetrics? {
        guard let image = CIImage(contentsOf: url) else { return nil }
        let extent = image.extent
        guard extent.width > 1, extent.height > 1 else { return nil }

        let targetMax: CGFloat = 320
        let scale = min(targetMax / max(extent.width, extent.height), 1)
        let sampled = image
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .cropped(to: CGRect(x: 0, y: 0, width: floor(extent.width * scale), height: floor(extent.height * scale)))

        guard let pixels = renderPixels(sampled) else { return nil }
        var lumas: [Double] = []
        lumas.reserveCapacity(pixels.width * pixels.height)

        var satSum = 0.0
        var warmthSum = 0.0
        var highCount = 0
        var shadowCount = 0
        var diffSum = 0.0
        var diffCount = 0
        var centerDiff = 0.0
        var centerCount = 0
        var edgeDiff = 0.0
        var edgeCount = 0
        var centerWarm = 0.0
        var centerWarmCount = 0
        var edgeWarm = 0.0
        var edgeWarmCount = 0

        for y in 0..<pixels.height {
            for x in 0..<pixels.width {
                let rgb = pixels.rgb(x: x, y: y)
                let luma = luminance(rgb)
                let saturation = max(rgb.r, rgb.g, rgb.b) - min(rgb.r, rgb.g, rgb.b)
                let warmth = rgb.r - rgb.b
                lumas.append(luma)
                satSum += saturation
                warmthSum += warmth
                if luma > 0.82 { highCount += 1 }
                if luma < 0.16 { shadowCount += 1 }

                let px = (Double(x) + 0.5) / Double(pixels.width)
                let py = (Double(y) + 0.5) / Double(pixels.height)
                let dist = hypot(px - 0.5, py - 0.5)
                if dist < 0.28 {
                    centerWarm += warmth
                    centerWarmCount += 1
                } else if dist > 0.44 {
                    edgeWarm += warmth
                    edgeWarmCount += 1
                }

                guard x + 1 < pixels.width, y + 1 < pixels.height else { continue }
                let right = luminance(pixels.rgb(x: x + 1, y: y))
                let down = luminance(pixels.rgb(x: x, y: y + 1))
                let diff = (abs(luma - right) + abs(luma - down)) * 0.5
                diffSum += diff
                diffCount += 1
                if dist < 0.28 {
                    centerDiff += diff
                    centerCount += 1
                } else if dist > 0.44 {
                    edgeDiff += diff
                    edgeCount += 1
                }
            }
        }

        lumas.sort()
        let count = max(lumas.count, 1)
        let p10 = percentile(lumas, 0.10)
        let p50 = percentile(lumas, 0.50)
        let p90 = percentile(lumas, 0.90)
        let relativePath = url.path.replacingOccurrences(of: root.path + "/", with: "")

        return ReferenceImageMetrics(
            path: relativePath,
            group: group(for: relativePath),
            width: Int(extent.width),
            height: Int(extent.height),
            meanLuma: lumas.reduce(0, +) / Double(count),
            medianLuma: p50,
            p10Luma: p10,
            p90Luma: p90,
            contrastSpan: p90 - p10,
            meanSaturation: satSum / Double(count),
            warmBias: warmthSum / Double(count),
            highlightPressure: Double(highCount) / Double(count),
            shadowPressure: Double(shadowCount) / Double(count),
            grainProxy: diffSum / Double(max(diffCount, 1)),
            edgeContrastRatio: (edgeDiff / Double(max(edgeCount, 1))) / max(centerDiff / Double(max(centerCount, 1)), 0.0001),
            edgeWarmShift: edgeWarm / Double(max(edgeWarmCount, 1)) - centerWarm / Double(max(centerWarmCount, 1))
        )
    }

    private static func renderPixels(_ image: CIImage) -> PixelBuffer? {
        let context = RenderContext.shared.context
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)
        guard width > 0, height > 0 else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        context.render(
            image,
            toBitmap: &bytes,
            rowBytes: width * 4,
            bounds: CGRect(x: 0, y: 0, width: width, height: height),
            format: .RGBA8,
            colorSpace: RenderContext.outputColorSpace
        )
        return PixelBuffer(width: width, height: height, bytes: bytes)
    }

    private static func summarize(_ metrics: [ReferenceImageMetrics]) -> [ReferenceGroupSummary] {
        Dictionary(grouping: metrics, by: \.group)
            .map { group, items in
                ReferenceGroupSummary(
                    group: group,
                    count: items.count,
                    meanLuma: average(items.map(\.meanLuma)),
                    contrastSpan: average(items.map(\.contrastSpan)),
                    meanSaturation: average(items.map(\.meanSaturation)),
                    warmBias: average(items.map(\.warmBias)),
                    highlightPressure: average(items.map(\.highlightPressure)),
                    shadowPressure: average(items.map(\.shadowPressure)),
                    grainProxy: average(items.map(\.grainProxy)),
                    edgeContrastRatio: average(items.map(\.edgeContrastRatio)),
                    edgeWarmShift: average(items.map(\.edgeWarmShift))
                )
            }
            .sorted { $0.group < $1.group }
    }

    private static func renderMarkdown(root: URL, metrics: [ReferenceImageMetrics], summaries: [ReferenceGroupSummary]) -> String {
        var lines: [String] = []
        lines.append("# Reference Analysis")
        lines.append("")
        lines.append("Generated from local research-only references in `\(root.path)`.")
        lines.append("")
        lines.append("## Group Summary")
        lines.append("")
        lines.append("| Group | Count | Luma | Contrast | Saturation | Warm Bias | Highlights | Shadows | Grain Proxy | Edge Contrast | Edge Warm Shift |")
        lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for summary in summaries {
            lines.append("| \(summary.group) | \(summary.count) | \(summary.meanLuma.rounded3) | \(summary.contrastSpan.rounded3) | \(summary.meanSaturation.rounded3) | \(summary.warmBias.rounded3) | \(summary.highlightPressure.rounded3) | \(summary.shadowPressure.rounded3) | \(summary.grainProxy.rounded3) | \(summary.edgeContrastRatio.rounded3) | \(summary.edgeWarmShift.rounded3) |")
        }
        lines.append("")
        lines.append("## Preset Implications")
        lines.append("")
        lines.append("- Higher `grainProxy` and lower `edgeContrastRatio` point toward stronger density grain, lower render resolution, and heavier edge softness.")
        lines.append("- Positive `warmBias` plus high `highlightPressure` points toward warm/red highlight bloom and stronger print rolloff.")
        lines.append("- Negative or low `warmBias` with elevated shadows points toward Fuji/cool cyan shadow profiles.")
        lines.append("- High saturation and contrast in app-filter references should be handled in `CameraResponseProfile`, not just global saturation.")
        lines.append("")
        lines.append("## Image Metrics")
        lines.append("")
        lines.append("| File | Group | Size | Luma | Contrast | Sat | Warm | Hi | Shadow | Grain | Edge Ratio |")
        lines.append("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for metric in metrics {
            lines.append("| `\(metric.path)` | \(metric.group) | \(metric.width)x\(metric.height) | \(metric.meanLuma.rounded3) | \(metric.contrastSpan.rounded3) | \(metric.meanSaturation.rounded3) | \(metric.warmBias.rounded3) | \(metric.highlightPressure.rounded3) | \(metric.shadowPressure.rounded3) | \(metric.grainProxy.rounded3) | \(metric.edgeContrastRatio.rounded3) |")
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func group(for path: String) -> String {
        if path.hasPrefix("dazz/parallax") { return "dazz-filter-comparisons" }
        if path.hasPrefix("dazz/") { return "dazz-organic" }
        if path.hasPrefix("huji/sarah") { return "huji-direct" }
        if path.hasPrefix("huji/") { return "huji-boards" }
        if path.contains("fuji-quicksnap") { return "fuji-quicksnap" }
        if path.contains("kodak-funsaver") { return "kodak-funsaver" }
        if path.hasPrefix("imperfections/") { return "imperfections" }
        if path.hasPrefix("app-screens/") { return "app-screens" }
        return "other"
    }

    private static func luminance(_ rgb: RGB) -> Double {
        rgb.r * 0.2126 + rgb.g * 0.7152 + rgb.b * 0.0722
    }

    private static func percentile(_ sorted: [Double], _ p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let index = max(0, min(sorted.count - 1, Int(Double(sorted.count - 1) * p)))
        return sorted[index]
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

private struct ReferenceReport: Encodable {
    var images: [ReferenceImageMetrics]
    var groups: [ReferenceGroupSummary]
}

private struct PixelBuffer {
    var width: Int
    var height: Int
    var bytes: [UInt8]

    func rgb(x: Int, y: Int) -> RGB {
        let index = (y * width + x) * 4
        return RGB(
            r: Double(bytes[index]) / 255.0,
            g: Double(bytes[index + 1]) / 255.0,
            b: Double(bytes[index + 2]) / 255.0
        )
    }
}

private struct RGB {
    var r: Double
    var g: Double
    var b: Double
}

private extension Double {
    var rounded3: String {
        String(format: "%.3f", self)
    }
}
