import SwiftUI

/// Create (`item == nil`) or edit a clip.
struct ClipEditView: View {
    @EnvironmentObject private var store: ClipStore
    @Environment(\.dismiss) private var dismiss

    let item: ClipItem?

    @State private var title: String
    @State private var text: String
    @State private var isPinned: Bool

    init(item: ClipItem?) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _text = State(initialValue: item?.text ?? "")
        // Manually created entries are usually reusable snippets → pinned by default.
        _isPinned = State(initialValue: item?.isPinned ?? true)
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Titel (optional)") {
                    TextField("z. B. Adresse, IBAN, E-Mail-Signatur", text: $title)
                }
                Section("Text") {
                    TextEditor(text: $text)
                        .frame(minHeight: 160)
                }
                Section {
                    Toggle("Angeheftet", isOn: $isPinned)
                } footer: {
                    Text("Angeheftete Einträge stehen oben und werden nie automatisch gelöscht.")
                }
            }
            .navigationTitle(item == nil ? "Neuer Eintrag" : "Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if var item {
            item.title = trimmedTitle.isEmpty ? nil : trimmedTitle
            item.text = text
            item.isPinned = isPinned
            store.update(item)
        } else {
            store.add(text, title: trimmedTitle, pinned: isPinned)
        }
        dismiss()
    }
}
