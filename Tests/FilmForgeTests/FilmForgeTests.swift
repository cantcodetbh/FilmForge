import XCTest

final class FilmForgeTests: XCTestCase {
    func testPresetCatalogContainsReferenceBuiltLooks() {
        let testFile = URL(fileURLWithPath: #filePath)
        let root = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let profileFile = root.appendingPathComponent("Sources/FilmForge/Profiles/ProfileCatalog.swift")
        let source = (try? String(contentsOf: profileFile)) ?? ""
        XCTAssertTrue(source.contains("Kodak FunSaver 800"))
        XCTAssertTrue(source.contains("Kodak FunSaver Overexposed"))
        XCTAssertTrue(source.contains("Fuji QuickSnap 400"))
        XCTAssertTrue(source.contains("Fuji QuickSnap Green"))
        XCTAssertTrue(source.contains("HUJI Direct"))
        XCTAssertTrue(source.contains("HUJI Board Dark"))
        XCTAssertTrue(source.contains("HUJI Light Leak"))
        XCTAssertTrue(source.contains("Dazz Organic"))
        XCTAssertTrue(source.contains("Dazz D Exp"))
        XCTAssertTrue(source.contains("Dazz CPM35"))
        XCTAssertTrue(source.contains("Dazz Night Market"))
        XCTAssertTrue(source.contains("Imperfect Lab Print"))
        XCTAssertTrue(source.contains("Kodak FunSaver Wedding"))
        XCTAssertTrue(source.contains("Kodak FunSaver Low Light"))
        XCTAssertTrue(source.contains("Kodak Sun Haze"))
        XCTAssertTrue(source.contains("Fuji Coastal Blue"))
        XCTAssertTrue(source.contains("Fuji Selfie Print"))
        XCTAssertTrue(source.contains("HUJI Red Leak"))
        XCTAssertTrue(source.contains("HUJI Alley Green"))
        XCTAssertTrue(source.contains("HUJI Date Night"))
        XCTAssertTrue(source.contains("Dazz Classic Room"))
        XCTAssertTrue(source.contains("Dazz DFuns Market"))
        XCTAssertTrue(source.contains("Dazz Soft Portrait"))
        XCTAssertTrue(source.contains("Dazz Parallax Dark"))
        XCTAssertTrue(source.contains("labScanProfile"))
        XCTAssertTrue(source.contains("controls("))
        XCTAssertGreaterThanOrEqual(source.components(separatedBy: "make(").count - 1, 24)
    }
}
