import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: ClipStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            List {
                Section("Tastatur einrichten") {
                    Step(number: 1, text: "Einstellungen → Allgemein → Tastatur → Tastaturen → Tastatur hinzufügen … → „ClipKeep“")
                    Step(number: 2, text: "Auf „ClipKeep“ tippen und „Vollen Zugriff erlauben“ aktivieren (nötig, damit die Tastatur deine Einträge lesen kann).")
                    Step(number: 3, text: "In jedem Textfeld auf 🌐 tippen/halten und ClipKeep wählen. Ein Tipp auf einen Eintrag fügt ihn ein.")
                    Button("iOS-Einstellungen öffnen") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section {
                    Step(number: 1, text: "Kurzbefehle-App → + → Aktion „Zwischenablage abrufen“")
                    Step(number: 2, text: "Aktion „In ClipKeep speichern“ hinzufügen, Text = Zwischenablage")
                    Step(number: 3, text: "Einstellungen → Bedienungshilfen → Tippen → Auf Rückseite tippen → Doppeltippen → deinen Kurzbefehl wählen")
                } header: {
                    Text("Blitzschnell speichern (optional)")
                } footer: {
                    Text("Danach speichert ein Doppeltipp auf die iPhone-Rückseite den kopierten Text – fast wie beim Samsung.")
                }

                Section("Daten") {
                    LabeledContent("Angeheftet", value: "\(store.pinned.count)")
                    LabeledContent("Verlauf", value: "\(store.history.count) / \(ClipStore.historyLimit)")
                    LabeledContent("Mit Tastatur geteilt", value: AppGroup.isAvailable ? "Ja" : "Nein – App Group fehlt")
                    Button("Verlauf löschen", role: .destructive) { confirmClear = true }
                        .disabled(store.history.isEmpty)
                }

                Section {
                    Text("Alle Einträge bleiben nur auf deinem iPhone. ClipKeep hat keinen Server und sendet nichts ins Internet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .confirmationDialog("Gesamten Verlauf löschen? Angeheftete Einträge bleiben erhalten.",
                                isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Verlauf löschen", role: .destructive) { store.clearHistory() }
            }
        }
    }
}

private struct Step: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor.opacity(0.2)))
            Text(text)
                .font(.subheadline)
        }
    }
}
