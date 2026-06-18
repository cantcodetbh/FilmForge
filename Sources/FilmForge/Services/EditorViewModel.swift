import AppKit
import CoreImage
import Foundation
import SwiftUI

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var imported: ImportedPhoto?
    @Published var preview: NSImage?
    @Published var selectedProfile: FilmLookProfile = ProfileCatalog.presets[0] {
        didSet {
            componentIntensities = selectedProfile.componentDefaults
            scheduleRender()
        }
    }
    @Published var componentIntensities: LookComponentIntensities = ProfileCatalog.presets[0].componentDefaults {
        didSet { scheduleRender() }
    }
    @Published var showBefore = false {
        didSet { scheduleRender() }
    }
    @Published var toggles = PipelineToggles() {
        didSet { scheduleRender() }
    }
    @Published var exportSettings = ExportSettings()
    @Published var isRendering = false
    @Published var status = "Import a JPEG, PNG, or HEIC to begin."

    private let importService = ImageImportService()
    private let previewRenderer = PreviewRenderer()
    private let exportService = ExportService()
    private var renderTask: Task<Void, Never>?

    func importImage() {
        guard let photo = importService.openPanel() else { return }
        imported = photo
        status = "Loaded \(photo.url.lastPathComponent)"
        scheduleRender()
    }

    func scheduleRender() {
        renderTask?.cancel()
        guard let imported else { return }
        let profile = selectedProfile
        let componentIntensities = componentIntensities
        let toggles = toggles
        let before = showBefore
        isRendering = true
        renderTask = Task { [previewRenderer] in
            let image = previewRenderer.previewImage(
                input: imported.image,
                profile: profile,
                componentIntensities: componentIntensities,
                toggles: toggles,
                showBefore: before,
                renderSeed: imported.renderSeed
            )

            guard !Task.isCancelled else { return }
            preview = image
            isRendering = false
        }
    }

    func exportImage() {
        guard let imported else { return }
        do {
            if let url = try exportService.export(
                imported: imported,
                profile: selectedProfile,
                componentIntensities: componentIntensities,
                toggles: toggles,
                settings: exportSettings,
                renderSeed: imported.renderSeed
            ) {
                status = "Exported \(url.lastPathComponent)"
            }
        } catch {
            status = "Export failed: \(error.localizedDescription)"
        }
    }
}
