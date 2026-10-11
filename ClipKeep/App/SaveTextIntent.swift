import AppIntents

/// Shortcuts action "In ClipKeep speichern".
/// Combine with "Get Clipboard" and Back Tap to save the clipboard without opening the app.
struct SaveTextIntent: AppIntent {
    static let title: LocalizedStringResource = "In ClipKeep speichern"
    static let description = IntentDescription("Speichert einen Text in deiner ClipKeep-Liste.")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Anheften", default: false)
    var pin: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$text) in ClipKeep speichern") {
            \.$pin
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard ClipStore().add(text, pinned: pin) else {
            return .result(dialog: "Kein Text zum Speichern.")
        }
        return .result(dialog: "In ClipKeep gespeichert ✓")
    }
}

struct ClipKeepShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveTextIntent(),
            phrases: ["Text in \(.applicationName) speichern"],
            shortTitle: "Text speichern",
            systemImageName: "doc.on.clipboard"
        )
    }
}
