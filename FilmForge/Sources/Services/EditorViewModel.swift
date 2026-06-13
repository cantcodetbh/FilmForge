import AppKit
import CoreImage
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var importedImage: ImportedImage?
    @Published var selectedCamera: CameraProfile = ProfileCatalog.cameras[0] {
        didSet { cameraChanged() }
    }
    @Published var selectedFilm: FilmStock = ProfileCatalog.defaultFilm(for: ProfileCatalog.cameras[0]) {
        didSet { profileChanged() }
    }
    @Published var adjustments: UserAdjustments = .neutral {
        didSet { schedulePreviewRender() }
    }
    @Published var previewImage: NSImage?
    @Published var originalPreviewImage: NSImage?
    @Published var showingOriginal = false
    @Published var isRendering = false
    @Published var isExporting = false
    @Published var showLabControls = false
    @Published var exportFormat: ExportFormat = .jpeg
    @Published var statusMessage = "Import a photo to begin."
    @Published var errorMessage: String?
    @Published var isDropTargeted = false

    let cameras = ProfileCatalog.cameras

    private let importService = ImageImportService()
    private let renderWorker = RenderWorker()
    private let exportService = ExportService()
    private var renderTask: Task<Void, Never>?

    var canExport: Bool {
        importedImage != nil && previewImage != nil && !isExporting
    }

    var activePreview: NSImage? {
        showingOriginal ? originalPreviewImage : previewImage
    }

    var compatibleFilms: [FilmStock] {
        ProfileCatalog.compatibleFilms(for: selectedCamera)
    }

    var selectedProfile: FilmProfile {
        ProfileCatalog.makeProfile(camera: selectedCamera, film: selectedFilm)
    }

    func openPhotoFromPanel() async {
        do {
            if let image = try await importService.openImageWithPanel() {
                await setImportedImage(image)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] data, _ in
            guard
                let self,
                let data,
                let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL?
            else { return }
            Task { @MainActor in
                do {
                    let image = try self.importService.loadImage(from: url)
                    await self.setImportedImage(image)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        return true
    }

    func resetAdjustments() {
        adjustments = selectedProfile.defaultAdjustments
    }

    func exportImage() async {
        guard let importedImage else { return }
        guard let url = exportService.chooseExportURL(defaultName: importedImage.displayName, format: exportFormat) else { return }
        isExporting = true
        statusMessage = "Rendering full-resolution export..."

        do {
            let profile = selectedProfile
            let adjustments = adjustments
            let format = exportFormat
            let cgImage = try await renderWorker.renderExport(image: importedImage, profile: profile, adjustments: adjustments)
            try exportService.write(cgImage, to: url, format: format, colorSpace: importedImage.outputColorSpace)
            statusMessage = "Exported \(url.lastPathComponent)."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Export failed."
        }

        isExporting = false
    }

    private func setImportedImage(_ image: ImportedImage) async {
        importedImage = image
        statusMessage = "Loaded \(image.displayName) • \(Int(image.pixelSize.width)) x \(Int(image.pixelSize.height))"
        errorMessage = nil
        selectedCamera = cameras[0]
        selectedFilm = ProfileCatalog.defaultFilm(for: selectedCamera)
        adjustments = selectedProfile.defaultAdjustments
        await renderOriginalPreview()
        schedulePreviewRender()
    }

    private func renderOriginalPreview() async {
        guard let importedImage else { return }
        do {
            originalPreviewImage = try await renderWorker.renderPreview(
                image: importedImage,
                profile: FilmProfile(
                    id: "neutral",
                    displayName: "Original",
                    tagline: "Source",
                    description: "Original image",
                    cameraName: "Original",
                    filmName: "None",
                    accent: ProfileAccent(red: 1, green: 1, blue: 1),
                    recipe: .neutral,
                    defaultAdjustments: .neutral
                ),
                adjustments: .neutral,
                maxLongEdge: 1800
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cameraChanged() {
        let films = compatibleFilms
        if !films.contains(where: { $0.id == selectedFilm.id }) {
            selectedFilm = ProfileCatalog.defaultFilm(for: selectedCamera)
            return
        }
        profileChanged()
    }

    private func profileChanged() {
        adjustments = selectedProfile.defaultAdjustments
        showLabControls = selectedProfile.recipe.output.labControlsEnabled
        schedulePreviewRender()
    }

    private func schedulePreviewRender() {
        renderTask?.cancel()
        guard let importedImage else { return }
        isRendering = true
        let image = importedImage
        let profile = selectedProfile
        let adjustments = adjustments

        renderTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            do {
                guard let self else { return }
                let rendered = try await self.renderWorker.renderPreview(image: image, profile: profile, adjustments: adjustments)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.previewImage = rendered
                    self.isRendering = false
                    self.statusMessage = "Previewing \(profile.displayName)."
                }
            } catch {
                await MainActor.run {
                    self?.isRendering = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
