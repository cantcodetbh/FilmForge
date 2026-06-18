import SwiftUI

struct ContentView: View {
    @StateObject private var model = EditorViewModel()

    var body: some View {
        HStack(spacing: 0) {
            mainCanvas
            Divider()
            AdvancedControlsView(model: model)
                .frame(width: 330)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.importImage()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Toggle(isOn: $model.showBefore) {
                    Label("Before", systemImage: "rectangle.split.2x1")
                }
                .toggleStyle(.button)

                Button {
                    model.exportImage()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(model.imported == nil)
            }
        }
        .onAppear {
            model.scheduleRender()
        }
    }

    private var mainCanvas: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                if let preview = model.preview {
                    Image(nsImage: preview)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(24)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 58, weight: .light))
                            .foregroundStyle(.secondary)
                        Button {
                            model.importImage()
                        } label: {
                            Label("Import Photo", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if model.isRendering {
                    ProgressView()
                        .controlSize(.large)
                        .padding(14)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .padding(16)
            }

            Divider()

            VStack(spacing: 10) {
                HStack {
                    Text(model.selectedProfile.name)
                        .font(.headline)
                    Text(model.selectedProfile.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        model.componentIntensities = model.selectedProfile.componentDefaults
                    } label: {
                        Label("Reset Mix", systemImage: "arrow.counterclockwise")
                    }
                }
                PresetStripView(selectedProfile: $model.selectedProfile)
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}
