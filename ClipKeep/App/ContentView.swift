import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: ClipStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var searchText = ""
    @State private var isAdding = false
    @State private var editing: ClipItem?
    @State private var showSettings = false
    @State private var toast: String?
    @State private var clipboardHasNewText = false
    @AppStorage("lastSeenChangeCount") private var lastSeenChangeCount = -1

    private var filtered: [ClipItem] {
        guard !searchText.isEmpty else { return store.items }
        return store.items.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
                || ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        let pinned = filtered.filter(\.isPinned)
        let history = filtered.filter { !$0.isPinned }

        NavigationStack {
            List {
                if clipboardHasNewText && searchText.isEmpty {
                    Section {
                        NewClipboardBanner(onPaste: save, onDismiss: markClipboardSeen)
                    }
                }
                if !pinned.isEmpty {
                    Section("Angeheftet") {
                        ForEach(pinned) { row($0) }
                    }
                }
                if !history.isEmpty {
                    Section("Verlauf") {
                        ForEach(history) { row($0) }
                    }
                }
            }
            .overlay {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "Noch nichts gespeichert",
                        systemImage: "doc.on.clipboard",
                        description: Text("Kopiere irgendwo einen Text und tippe hier auf „Einsetzen“ – oder lege mit + einen eigenen Textbaustein an.")
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText, prompt: "Suchen")
            .navigationTitle("ClipKeep")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Einstellungen")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // PasteButton reads the clipboard without the iOS "Allow Paste" prompt.
                    PasteButton(payloadType: String.self) { strings in
                        Task { @MainActor in save(strings) }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.capsule)

                    Button { isAdding = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neuer Eintrag")
                }
            }
            .sheet(isPresented: $isAdding) {
                ClipEditView(item: nil).environmentObject(store)
            }
            .sheet(item: $editing) { item in
                ClipEditView(item: item).environmentObject(store)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(store)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear(perform: checkClipboard)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.reload()
                checkClipboard()
            }
        }
    }

    private func row(_ item: ClipItem) -> some View {
        ClipRow(item: item)
            .contentShape(Rectangle())
            .onTapGesture { copy(item) }
            .swipeActions(edge: .leading) {
                Button { store.togglePin(item) } label: {
                    Label(item.isPinned ? "Lösen" : "Anheften",
                          systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { store.delete(item) } label: {
                    Label("Löschen", systemImage: "trash")
                }
                Button { editing = item } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                .tint(.blue)
            }
            .contextMenu {
                Button { copy(item) } label: { Label("Kopieren", systemImage: "doc.on.doc") }
                Button { editing = item } label: { Label("Bearbeiten", systemImage: "pencil") }
                Button { store.togglePin(item) } label: {
                    Label(item.isPinned ? "Lösen" : "Anheften",
                          systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                ShareLink(item: item.text) { Label("Teilen", systemImage: "square.and.arrow.up") }
                Divider()
                Button(role: .destructive) { store.delete(item) } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
    }

    private func copy(_ item: ClipItem) {
        UIPasteboard.general.string = item.text
        // Our own copy must not trigger the "new clipboard" banner.
        lastSeenChangeCount = UIPasteboard.general.changeCount
        clipboardHasNewText = false
        store.markUsed(item)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Kopiert")
    }

    private func save(_ strings: [String]) {
        let added = strings.filter { store.add($0) }.count
        markClipboardSeen()
        showToast(added > 0 ? "Gespeichert" : "Kein Text in der Zwischenablage")
    }

    /// `hasStrings` / `changeCount` don't trigger the paste prompt, so we can check freely.
    private func checkClipboard() {
        let pasteboard = UIPasteboard.general
        clipboardHasNewText = pasteboard.hasStrings && pasteboard.changeCount != lastSeenChangeCount
    }

    private func markClipboardSeen() {
        lastSeenChangeCount = UIPasteboard.general.changeCount
        withAnimation { clipboardHasNewText = false }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { if toast == message { toast = nil } }
        }
    }
}

private struct NewClipboardBanner: View {
    let onPaste: ([String]) -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Neuer Text in der Zwischenablage")
                    .font(.subheadline.weight(.semibold))
                Text("Jetzt in ClipKeep speichern?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PasteButton(payloadType: String.self) { strings in
                Task { @MainActor in onPaste(strings) }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Ausblenden")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView().environmentObject(ClipStore())
}
