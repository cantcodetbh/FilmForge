import SwiftUI

@main
struct FilmForgeApp: App {
    @StateObject private var editor = EditorViewModel()

    var body: some Scene {
        WindowGroup {
            EditorView()
                .environmentObject(editor)
                .frame(minWidth: 1180, minHeight: 760)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Photo...") {
                    Task { await editor.openPhotoFromPanel() }
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Export Processed Image...") {
                    Task { await editor.exportImage() }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(!editor.canExport)
            }
        }
    }
}
