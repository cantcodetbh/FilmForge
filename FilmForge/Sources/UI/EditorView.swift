import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.055, blue: 0.06)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView()
                    .frame(width: 306)

                Divider()
                    .overlay(.white.opacity(0.08))

                PreviewPane()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .overlay(.white.opacity(0.08))

                InspectorView()
                    .frame(width: 318)
            }
        }
        .foregroundStyle(.white)
        .alert("FilmForge", isPresented: Binding(
            get: { editor.errorMessage != nil },
            set: { if !$0 { editor.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { editor.errorMessage = nil }
        } message: {
            Text(editor.errorMessage ?? "")
        }
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("FilmForge")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Original camera recipes for imported photos.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)

            Button {
                Task { await editor.openPhotoFromPanel() }
            } label: {
                Label("Import Photo", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 18)

            if let imported = editor.importedImage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(imported.displayName)
                        .lineLimit(1)
                        .font(.headline)
                    Text("\(Int(imported.pixelSize.width)) x \(Int(imported.pixelSize.height)) px")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }
                .padding(.horizontal, 18)
            }

            Text("Cameras")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 18)
                .padding(.top, 4)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(editor.cameras) { camera in
                        CameraCard(camera: camera, selected: camera.id == editor.selectedCamera.id)
                            .onTapGesture {
                                editor.selectedCamera = camera
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 18)
            }
        }
        .background(Color(red: 0.075, green: 0.075, blue: 0.085))
    }
}

private struct CameraCard: View {
    let camera: CameraProfile
    let selected: Bool

    var accent: Color {
        Color(red: camera.accent.red, green: camera.accent.green, blue: camera.accent.blue)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.95), accent.opacity(0.28), .black.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                        .padding(12)
                }
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(camera.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(camera.tagline)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(selected ? accent.opacity(0.18) : Color.white.opacity(0.045))
                .stroke(selected ? accent.opacity(0.75) : Color.white.opacity(0.07), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

private struct PreviewPane: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(editor.selectedProfile.displayName)
                        .font(.title2.weight(.semibold))
                    Text(editor.selectedProfile.description)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(2)
                }

                Spacer()

                Toggle(isOn: $editor.showingOriginal) {
                    Label("Original", systemImage: "rectangle.split.2x1")
                }
                .toggleStyle(.button)
                .disabled(editor.originalPreviewImage == nil)

                if editor.isRendering {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.04)

                if let image = editor.activePreview {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .shadow(color: .black.opacity(0.55), radius: 32, x: 0, y: 18)
                        .padding(34)
                } else {
                    EmptyStateView()
                        .padding(36)
                }

                if editor.isDropTargeted {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                        .background(Color.white.opacity(0.06))
                        .padding(28)
                }
            }
            .onDrop(
                of: [UTType.fileURL.identifier],
                isTargeted: $editor.isDropTargeted,
                perform: editor.importDroppedProviders
            )

            HStack {
                Text(editor.statusMessage)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                Spacer()
                Text(editor.showingOriginal ? "Before" : "Processed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
            }
            .font(.caption)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.18))
        }
    }
}

private struct EmptyStateView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(.white.opacity(0.75))
            VStack(spacing: 7) {
                Text("Drop a photo here")
                    .font(.title3.weight(.semibold))
                Text("FilmForge edits existing images only. No camera capture, no cloud, no account.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            Button {
                Task { await editor.openPhotoFromPanel() }
            } label: {
                Label("Choose Photo", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

private struct InspectorView: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Camera Mode")
                        .font(.headline)
                    Text("Choose the look. The Lab is optional.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
            }
            .padding(18)

            ScrollView {
                VStack(spacing: 16) {
                    FilmPicker()
                    ModeSignatureCard(profile: editor.selectedProfile)

                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            editor.showLabControls.toggle()
                        }
                    } label: {
                        HStack {
                            Label(editor.showLabControls ? "Hide Lab" : "Open Lab", systemImage: "slider.horizontal.3")
                            Spacer()
                            Image(systemName: editor.showLabControls ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))

                    if editor.showLabControls {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Lab Adjustments")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Button {
                                    editor.resetAdjustments()
                                } label: {
                                    Label("Reset", systemImage: "arrow.counterclockwise")
                                }
                                .labelStyle(.iconOnly)
                                .help("Reset controls")
                            }
                            .padding(.horizontal, 2)

                            SliderRow(title: "Intensity", systemImage: "dial.high", value: $editor.adjustments.intensity, range: 0...1.4, format: .percent)
                            SliderRow(title: "Exposure", systemImage: "plusminus.circle", value: $editor.adjustments.exposure, range: -1.5...1.5, format: .signedDecimal)
                            SliderRow(title: "Temperature", systemImage: "thermometer.sun", value: $editor.adjustments.temperature, range: -1...1, format: .signedDecimal)
                            SliderRow(title: "Tint", systemImage: "eyedropper.halffull", value: $editor.adjustments.tint, range: -1...1, format: .signedDecimal)
                            SliderRow(title: "Grain", systemImage: "circle.grid.cross", value: $editor.adjustments.grain, range: 0...2, format: .percent)
                            SliderRow(title: "Bloom", systemImage: "sparkle.magnifyingglass", value: $editor.adjustments.bloom, range: 0...2, format: .percent)
                            SliderRow(title: "Halation", systemImage: "sun.max", value: $editor.adjustments.halation, range: 0...2, format: .percent)
                            SliderRow(title: "Vignette", systemImage: "circle.dashed", value: $editor.adjustments.vignette, range: 0...2, format: .percent)
                            SliderRow(title: "Fade", systemImage: "shadow", value: $editor.adjustments.fade, range: 0...1, format: .percent)
                            SliderRow(title: "Softness", systemImage: "camera.aperture", value: $editor.adjustments.softness, range: 0...2, format: .percent)
                            SliderRow(title: "Dust", systemImage: "wand.and.stars", value: $editor.adjustments.dust, range: 0...2, format: .percent)

                            Toggle(isOn: $editor.adjustments.borderEnabled) {
                                Label("Border", systemImage: "rectangle.inset.filled")
                            }
                            .toggleStyle(.switch)
                            .padding(12)
                            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }

            Divider()
                .overlay(.white.opacity(0.08))

            VStack(spacing: 12) {
                Picker("Format", selection: $editor.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(editor.importedImage == nil)

                Button {
                    Task { await editor.exportImage() }
                } label: {
                    if editor.isExporting {
                        Label("Exporting...", systemImage: "hourglass")
                    } else {
                        Label("Export Image", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!editor.canExport)
            }
            .padding(16)
        }
        .background(Color(red: 0.075, green: 0.075, blue: 0.085))
    }
}

private struct FilmPicker: View {
    @EnvironmentObject private var editor: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Film Stock", systemImage: "film")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(editor.selectedFilm.family.rawValue)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Picker("Film / Mode", selection: $editor.selectedFilm) {
                ForEach(editor.compatibleFilms) { film in
                    Text(film.displayName).tag(film)
                }
            }
            .labelsHidden()

            Text(editor.selectedFilm.tagline)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ModeSignatureCard: View {
    let profile: FilmProfile

    private var traits: [String] {
        var values: [String] = []
        let recipe = profile.recipe
        switch recipe.output.aspect {
        case .original: values.append("native frame")
        case .threeByTwo: values.append("3:2 crop")
        case .square: values.append("square")
        case .halfFrame: values.append("half-frame")
        case .instant: values.append("instant frame")
        }
        if recipe.output.palette != .natural {
            values.append(recipe.output.palette.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).lowercased())
        }
        if recipe.output.posterizeLevels > 1 {
            values.append("\(Int(recipe.output.posterizeLevels)) tone")
        }
        if recipe.output.flashFalloff > 0.01 {
            values.append("flash falloff")
        }
        if recipe.output.dateStamp {
            values.append("date stamp")
        }
        if recipe.output.jpegCrunch > 0.4 {
            values.append("jpeg crunch")
        }
        if recipe.output.chromaBleed > 0.35 {
            values.append("chroma bleed")
        }
        if recipe.output.lightLeak > 0.2 {
            values.append("light leak")
        }
        if recipe.output.scanlines > 0.2 {
            values.append("scanlines")
        }
        switch recipe.lens.fisheye.projection {
        case .none:
            break
        case .diagonal:
            values.append("full fisheye")
        case .circular:
            values.append("circle fisheye")
        case .croppedCircular:
            values.append("cropped fisheye")
        }
        if recipe.grain.amount > 0.55 {
            values.append("heavy grain")
        } else if recipe.grain.amount > 0.2 {
            values.append("fine grain")
        }
        if recipe.vignette.amount > 0.65 {
            values.append("dark corners")
        }
        if recipe.bloom.amount > 0.1 {
            values.append("glow")
        }
        return Array(values.prefix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(profile.filmName, systemImage: "camera.filters")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(profile.cameraName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Text(profile.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(4)

            FlowTags(tags: traits)
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 7)], alignment: .leading, spacing: 7) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private enum SliderValueFormat {
    case percent
    case signedDecimal
}

private struct SliderRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: SliderValueFormat

    var valueLabel: String {
        switch format {
        case .percent:
            return "\(Int((value * 100).rounded()))%"
        case .signedDecimal:
            let sign = value >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.2f", value))"
        }
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(valueLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.58))
            }
            Slider(value: $value, in: range)
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }
}
