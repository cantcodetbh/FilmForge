import SwiftUI

struct AdvancedControlsView: View {
    @ObservedObject var model: EditorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GroupBox("Preset Mix") {
                    VStack(alignment: .leading, spacing: 10) {
                        componentSlider("Tone", value: $model.componentIntensities.tone)
                        componentSlider("Colour", value: $model.componentIntensities.colour)
                        componentSlider("LUT", value: $model.componentIntensities.lut)
                        componentSlider("Grain", value: $model.componentIntensities.grain)
                        componentSlider("Softness", value: $model.componentIntensities.softness)
                        componentSlider("Glow", value: $model.componentIntensities.glow)
                        componentSlider("Lens", value: $model.componentIntensities.lens)
                        componentSlider("Artefacts", value: $model.componentIntensities.artefacts)
                    }
                }

                GroupBox("Pipeline") {
                    toggleGrid
                }

                GroupBox("Artefacts") {
                    artefactsSubGrid
                }

                GroupBox("Tone") {
                    valueRows([
                        ("Exposure", model.selectedProfile.baseExposure),
                        ("Contrast", model.selectedProfile.contrast),
                        ("Toe", model.selectedProfile.toeStrength),
                        ("Shoulder", model.selectedProfile.shoulderStrength),
                        ("Black", model.selectedProfile.blackPoint),
                        ("White", model.selectedProfile.whitePoint),
                        ("Push/Pull", model.selectedProfile.pushPull)
                    ])
                }

                GroupBox("Colour") {
                    valueRows([
                        ("Saturation", model.selectedProfile.saturation),
                        ("Vibrance", model.selectedProfile.vibrance),
                        ("Temp Bias", model.selectedProfile.colourTemperatureBias),
                        ("Tint Bias", model.selectedProfile.tintBias)
                    ])
                }

                GroupBox("Camera Response") {
                    valueRows([
                        ("Separation", model.selectedProfile.cameraResponseProfile.colorSeparation),
                        ("Cross Process", model.selectedProfile.cameraResponseProfile.crossProcess),
                        ("Cyan Shadows", model.selectedProfile.cameraResponseProfile.cyanShadow),
                        ("Warm Highlights", model.selectedProfile.cameraResponseProfile.warmHighlight),
                        ("Red Bloom", model.selectedProfile.cameraResponseProfile.redChannelBloom),
                        ("Dye Contam", model.selectedProfile.cameraResponseProfile.dyeContamination),
                        ("Scan Fade", model.selectedProfile.cameraResponseProfile.scanFade),
                        ("Cheapness", model.selectedProfile.cameraResponseProfile.cheapness)
                    ])
                }

                GroupBox("LUT") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(model.selectedProfile.lutName ?? "None")
                            Spacer()
                            Text("\(Int(model.selectedProfile.lutIntensity * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Toggle("LUT-only export", isOn: $model.exportSettings.lutOnly)
                    }
                }

                GroupBox("Grain") {
                    valueRows([
                        ("Preset", model.selectedProfile.grainProfile.preset.rawValue),
                        ("Size", model.selectedProfile.grainProfile.size),
                        ("Roughness", model.selectedProfile.grainProfile.roughness),
                        ("Strength", model.selectedProfile.grainProfile.strength),
                        ("Chroma", model.selectedProfile.grainProfile.chromaAmount),
                        ("Shadows", model.selectedProfile.grainProfile.shadowAmount),
                        ("Midtones", model.selectedProfile.grainProfile.midtoneAmount),
                        ("Highlights", model.selectedProfile.grainProfile.highlightAmount),
                        ("Resolution", model.selectedProfile.grainProfile.resolution)
                    ])
                }

                GroupBox("Halation") {
                    valueRows([
                        ("Intensity", model.selectedProfile.halationProfile.intensity),
                        ("Threshold", model.selectedProfile.halationProfile.threshold),
                        ("Radius", model.selectedProfile.halationProfile.radius),
                        ("Blend", model.selectedProfile.halationProfile.blend)
                    ])
                }

                GroupBox("Bloom") {
                    valueRows([
                        ("Threshold", model.selectedProfile.bloomProfile.threshold),
                        ("Radius", model.selectedProfile.bloomProfile.radius),
                        ("Intensity", model.selectedProfile.bloomProfile.intensity),
                        ("Softness", model.selectedProfile.bloomProfile.softness)
                    ])
                }

                GroupBox("Lens") {
                    valueRows([
                        ("Vignette", model.selectedProfile.vignetteProfile.intensity),
                        ("Vignette Blue", model.selectedProfile.vignetteProfile.blueBias),
                        ("Aberration", model.selectedProfile.lensProfile.chromaticAberration),
                        ("Edge Softness", model.selectedProfile.lensProfile.edgeSoftness),
                        ("Compact Blur", model.selectedProfile.lensProfile.compactBlur),
                        ("Film Flatness", model.selectedProfile.filmFlatnessProfile.intensity)
                    ])
                }

                GroupBox("Artefacts") {
                    valueRows([
                        ("Dust", model.selectedProfile.dustProfile.dustAmount),
                        ("Scratches", model.selectedProfile.dustProfile.scratchAmount),
                        ("Light Leak", model.selectedProfile.dustProfile.lightLeakAmount),
                        ("Date Stamp", model.selectedProfile.dateStampProfile.enabled ? "On" : "Off"),
                        ("Shadow Shift", model.selectedProfile.labScanProfile.shadowColorShift),
                        ("Scanner Noise", model.selectedProfile.labScanProfile.scannerNoiseAmount)
                    ])
                }

                GroupBox("Export") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Format", selection: $model.exportSettings.format) {
                            ForEach(ExportFormat.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Colour Space", selection: $model.exportSettings.outputColorSpaceName) {
                            Text("sRGB").tag("sRGB")
                            Text("Display P3").tag("Display P3")
                        }
                        HStack {
                            Text("JPEG Quality")
                            Slider(value: $model.exportSettings.jpegQuality, in: 0.55...1)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var toggleGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
            GridRow {
                Toggle("Tone", isOn: $model.toggles.tone)
                Toggle("LUT", isOn: $model.toggles.lut)
            }
            GridRow {
                Toggle("Grain", isOn: $model.toggles.grain)
                Toggle("Halation", isOn: $model.toggles.halation)
            }
            GridRow {
                Toggle("Bloom", isOn: $model.toggles.bloom)
                Toggle("Lens", isOn: $model.toggles.lens)
            }
            GridRow {
                Toggle("Artefacts", isOn: $model.toggles.artefacts)
                Toggle("X-Pro", isOn: $model.toggles.xpro)
            }
        }
    }

    private var artefactsSubGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Dust & Scratches", isOn: $model.toggles.dustScratches)
            Toggle("Light Leaks", isOn: $model.toggles.lightLeaks)
            Toggle("Lab Scan", isOn: $model.toggles.labScan)
            Toggle("Date Stamp", isOn: $model.toggles.dateStamp)
        }
        .disabled(!model.toggles.artefacts)
        .font(.callout)
    }

    private func componentSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: 0...1.5)
        }
        .font(.callout)
    }

    @ViewBuilder
    private func valueRows(_ rows: [(String, Any)]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(format(row.1))
                        .monospacedDigit()
                }
                .font(.callout)
            }
        }
    }

    private func format(_ value: Any) -> String {
        if let value = value as? Double {
            return abs(value) >= 10 ? String(format: "%.0f", value) : String(format: "%.2f", value)
        }
        return String(describing: value)
    }
}
