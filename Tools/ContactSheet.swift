import AppKit
import CoreImage
import Foundation

@main
struct ContactSheet {
    static func main() throws {
        let renderer = PreviewRenderer()
        let source = makeReferenceImage(size: CGSize(width: 420, height: 280))
        let profiles = heroProfiles()
        let tile = CGSize(width: 280, height: 220)
        let columns = 4
        let rows = Int(ceil(Double(profiles.count) / Double(columns)))
        let sheetSize = CGSize(width: tile.width * CGFloat(columns), height: tile.height * CGFloat(rows))
        let sheet = NSImage(size: sheetSize)

        sheet.lockFocus()
        NSColor(calibratedWhite: 0.045, alpha: 1).setFill()
        NSRect(origin: .zero, size: sheetSize).fill()

        for (index, profile) in profiles.enumerated() {
            let image = try renderer.renderPreview(
                source: source,
                profile: profile,
                adjustments: profile.defaultAdjustments,
                maxLongEdge: 280
            )
            let col = index % columns
            let row = rows - 1 - index / columns
            let origin = CGPoint(x: CGFloat(col) * tile.width, y: CGFloat(row) * tile.height)
            let imageRect = CGRect(x: origin.x + 10, y: origin.y + 34, width: tile.width - 20, height: tile.height - 48)
            image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
            drawLabel(profile.displayName, in: CGRect(x: origin.x + 10, y: origin.y + 10, width: tile.width - 20, height: 18))
        }

        sheet.unlockFocus()

        guard let data = sheet.pngData() else { throw FilmPipelineError.renderFailed }
        let outputURL = URL(fileURLWithPath: "/tmp/FilmForgeContactSheet.png")
        try data.write(to: outputURL)
        print("Wrote \(outputURL.path)")
    }

    private static func heroProfiles() -> [FilmProfile] {
        let picks: [(CameraProfile, String)] = [
            (ProfileCatalog.canonAE1, "portra"),
            (ProfileCatalog.canonAE1, "e100-slide"),
            (ProfileCatalog.lomoLCA, "xpro-slide"),
            (ProfileCatalog.holga120N, "holga-leak"),
            (ProfileCatalog.dianaF, "diana-xpro"),
            (ProfileCatalog.disposableFlash, "flash-party"),
            (ProfileCatalog.sonyF707, "purple-fringe"),
            (ProfileCatalog.miniDVGrab, "tape-still"),
            (ProfileCatalog.canonG2, "low-res"),
            (ProfileCatalog.fxnR, "amber-cafe")
        ]
        return picks.compactMap { camera, suffix in
            ProfileCatalog.compatibleFilms(for: camera)
                .first { $0.id.contains(suffix) }
                .map { ProfileCatalog.makeProfile(camera: camera, film: $0) }
        }
    }

    private static func makeReferenceImage(size: CGSize) -> CIImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
        NSRect(origin: .zero, size: size).fill()

        let colors: [NSColor] = [
            .systemRed, .systemOrange, .systemYellow, .systemGreen,
            .systemTeal, .systemBlue, .systemPurple, .systemPink,
            .white, .lightGray, .darkGray, .black
        ]
        let swatchWidth = size.width / CGFloat(colors.count)
        for (index, color) in colors.enumerated() {
            color.setFill()
            NSRect(x: CGFloat(index) * swatchWidth, y: 0, width: swatchWidth + 1, height: size.height * 0.24).fill()
        }

        for step in 0..<128 {
            let value = CGFloat(step) / 127
            NSColor(calibratedRed: value, green: value, blue: value, alpha: 1).setFill()
            NSRect(x: CGFloat(step) * size.width / 128, y: size.height * 0.24, width: size.width / 128 + 1, height: size.height * 0.18).fill()
        }

        NSColor(calibratedRed: 0.9, green: 0.74, blue: 0.58, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 34, y: size.height * 0.52, width: 112, height: 112)).fill()
        NSColor(calibratedRed: 0.18, green: 0.42, blue: 0.86, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 176, y: size.height * 0.54, width: 90, height: 100)).fill()
        NSColor(calibratedRed: 0.92, green: 0.92, blue: 0.84, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 298, y: size.height * 0.56, width: 84, height: 84)).fill()

        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let cgImage = bitmap.cgImage
        else {
            return CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5)).cropped(to: CGRect(origin: .zero, size: size))
        }
        return CIImage(cgImage: cgImage)
    }

    private static func drawLabel(_ text: String, in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.9, alpha: 1),
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
