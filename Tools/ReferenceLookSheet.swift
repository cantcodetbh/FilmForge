import AppKit
import CoreImage
import Foundation

@main
struct ReferenceLookSheet {
    static func main() throws {
        let renderer = PreviewRenderer()
        let sources = try loadSources()
        let films = ProfileCatalog.compatibleFilms(for: ProfileCatalog.referenceLooks)
        let profiles = films.map { ProfileCatalog.makeProfile(camera: ProfileCatalog.referenceLooks, film: $0) }

        let tile = CGSize(width: 260, height: 330)
        let columns = profiles.count
        let rows = sources.count
        let sheetSize = CGSize(width: tile.width * CGFloat(columns), height: tile.height * CGFloat(rows))
        let sheet = NSImage(size: sheetSize)

        sheet.lockFocus()
        NSColor(calibratedWhite: 0.035, alpha: 1).setFill()
        NSRect(origin: .zero, size: sheetSize).fill()

        for (rowIndex, source) in sources.enumerated() {
            for (columnIndex, profile) in profiles.enumerated() {
                let rendered = try renderer.renderPreview(
                    source: source.image,
                    profile: profile,
                    adjustments: profile.defaultAdjustments,
                    maxLongEdge: 300
                )
                let origin = CGPoint(
                    x: CGFloat(columnIndex) * tile.width,
                    y: CGFloat(rows - 1 - rowIndex) * tile.height
                )
                let imageRect = CGRect(x: origin.x + 10, y: origin.y + 44, width: tile.width - 20, height: tile.height - 70)
                rendered.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
                drawLabel(profile.filmName, in: CGRect(x: origin.x + 10, y: origin.y + 22, width: tile.width - 20, height: 16))
                drawLabel(source.name, in: CGRect(x: origin.x + 10, y: origin.y + 8, width: tile.width - 20, height: 13), size: 9, alpha: 0.58)
            }
        }

        sheet.unlockFocus()

        guard let data = sheet.pngData() else { throw FilmPipelineError.renderFailed }
        let outputURL = URL(fileURLWithPath: "/tmp/FilmForgeReferenceLooks.png")
        try data.write(to: outputURL)
        print("Wrote \(outputURL.path)")
    }

    private static func loadSources() throws -> [(name: String, image: CIImage)] {
        let paths = [
            ("window cat", "/Users/josh/Pictures/Photos Library.photoslibrary/resources/derivatives/A/A8CCB7AC-2A67-4DE6-B074-66F2E75075FE_1_105_c.jpeg"),
            ("garden child", "/Users/josh/Pictures/Photos Library.photoslibrary/resources/derivatives/E/E17C871F-0E3B-416C-9EF9-B2DC29573B71_1_105_c.jpeg"),
            ("couch", "/Users/josh/Pictures/Photos Library.photoslibrary/resources/derivatives/6/6D78E372-1DD7-4E77-BC46-2BEAA978B76F_1_105_c.jpeg"),
            ("portrait", "/Users/josh/Pictures/Photos Library.photoslibrary/resources/derivatives/6/6A0CF8B4-AA67-4F82-8F8D-BFC30BC79DAC_1_102_o.jpeg")
        ]

        return paths.compactMap { name, path in
            guard let image = CIImage(contentsOf: URL(fileURLWithPath: path)) else { return nil }
            return (name, image.oriented(.up))
        }
    }

    private static func drawLabel(_ text: String, in rect: CGRect, size: CGFloat = 11, alpha: CGFloat = 0.9) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.92, alpha: alpha),
            .paragraphStyle: paragraph
        ]
        NSString(string: text).draw(in: rect, withAttributes: attrs)
    }
}

private extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
