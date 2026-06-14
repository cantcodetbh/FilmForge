import AppKit
import CoreImage
import Foundation

@main
struct FisheyeSheet {
    static func main() throws {
        let renderer = PreviewRenderer()
        let source = makeGridReference(size: CGSize(width: 420, height: 280))
        let profiles = fisheyeProfiles()
        let tile = CGSize(width: 320, height: 250)
        let columns = 2
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
                maxLongEdge: 300
            )
            let col = index % columns
            let row = rows - 1 - index / columns
            let origin = CGPoint(x: CGFloat(col) * tile.width, y: CGFloat(row) * tile.height)
            let imageRect = CGRect(x: origin.x + 10, y: origin.y + 36, width: tile.width - 20, height: tile.height - 52)
            image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
            drawLabel(profile.displayName, in: CGRect(x: origin.x + 10, y: origin.y + 12, width: tile.width - 20, height: 18))
        }

        sheet.unlockFocus()

        guard let data = sheet.pngData() else { throw FilmPipelineError.renderFailed }
        let outputURL = URL(fileURLWithPath: "/tmp/FilmForgeFisheyeSheet.png")
        try data.write(to: outputURL)
        print("Wrote \(outputURL.path)")
    }

    private static func fisheyeProfiles() -> [FilmProfile] {
        ProfileCatalog.cameras.flatMap { camera in
            ProfileCatalog.compatibleFilms(for: camera).compactMap { film -> FilmProfile? in
                let profile = ProfileCatalog.makeProfile(camera: camera, film: film)
                return profile.recipe.lens.fisheye.projection == .none ? nil : profile
            }
        }
    }

    private static func makeGridReference(size: CGSize) -> CIImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
        NSRect(origin: .zero, size: size).fill()

        let gridColor = NSColor(calibratedWhite: 0.82, alpha: 1)
        gridColor.setStroke()
        for x in stride(from: CGFloat(0), through: size.width, by: 28) {
            let path = NSBezierPath()
            path.move(to: CGPoint(x: x, y: 0))
            path.line(to: CGPoint(x: x, y: size.height))
            path.lineWidth = x == size.width / 2 ? 2 : 1
            path.stroke()
        }
        for y in stride(from: CGFloat(0), through: size.height, by: 28) {
            let path = NSBezierPath()
            path.move(to: CGPoint(x: 0, y: y))
            path.line(to: CGPoint(x: size.width, y: y))
            path.lineWidth = y == size.height / 2 ? 2 : 1
            path.stroke()
        }

        let colors: [NSColor] = [.systemRed, .systemYellow, .systemGreen, .systemBlue, .systemPurple]
        for (index, color) in colors.enumerated() {
            color.setFill()
            let rect = NSRect(x: 28 + CGFloat(index) * 74, y: 28, width: 44, height: 44)
            NSBezierPath(ovalIn: rect).fill()
        }

        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: size.width / 2 - 34, y: size.height / 2 - 34, width: 68, height: 68)).fill()
        NSColor.black.setStroke()
        NSBezierPath(ovalIn: NSRect(x: size.width / 2 - 34, y: size.height / 2 - 34, width: 68, height: 68)).stroke()

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
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.9, alpha: 1)
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
