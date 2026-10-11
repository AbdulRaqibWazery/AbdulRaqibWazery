import SwiftUI
import UIKit

/// Bridge between the SwiftUI keyboard and `UIInputViewController`.
final class KeyboardModel: ObservableObject {
    @Published var needsGlobe = true
    @Published var hasFullAccess = false
    var insertText: (String) -> Void = { _ in }
    var deleteBackward: () -> Void = {}
    var nextKeyboard: () -> Void = {}
}

struct KeyboardView: View {
    @ObservedObject var store: ClipStore
    @ObservedObject var model: KeyboardModel

    @State private var tab: Tab = .pinned
    @State private var flashedID: UUID?

    enum Tab: Hashable { case pinned, history }

    private var items: [ClipItem] {
        tab == .pinned ? store.pinned : store.history
    }

    var body: some View {
        VStack(spacing: 6) {
            Picker("Liste", selection: $tab) {
                Text("Angeheftet (\(store.pinned.count))").tag(Tab.pinned)
                Text("Verlauf (\(store.history.count))").tag(Tab.history)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
        .onAppear {
            if store.pinned.isEmpty && !store.history.isEmpty { tab = .history }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !model.hasFullAccess {
            hint(
                icon: "lock.fill",
                text: "Bitte „Vollen Zugriff erlauben“ aktivieren:\nEinstellungen → Allgemein → Tastatur → Tastaturen → ClipKeep"
            )
        } else if items.isEmpty {
            hint(
                icon: "doc.on.clipboard",
                text: tab == .pinned
                    ? "Keine angehefteten Einträge.\nIn der ClipKeep-App nach rechts wischen zum Anheften."
                    : "Verlauf ist leer.\nTippe unten auf „Sichern“, um die Zwischenablage zu speichern."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(items) { item in
                        Button { insert(item) } label: { clipCell(item) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
        }
    }

    private func clipCell(_ item: ClipItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.displayTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            if item.title?.isEmpty == false {
                Text(item.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(flashedID == item.id ? Color.accentColor.opacity(0.35) : Color(uiColor: .systemBackground))
        )
        .shadow(color: .black.opacity(0.15), radius: 0, y: 1)
        .contentShape(Rectangle())
    }

    private var bottomBar: some View {
        HStack(spacing: 6) {
            if model.needsGlobe {
                KeyButton(systemImage: "globe", width: 44, action: model.nextKeyboard)
            }
            if model.hasFullAccess {
                KeyButton(systemImage: "square.and.arrow.down", title: "Sichern", width: 96) {
                    saveClipboard()
                }
            }
            KeyButton(title: "Leerzeichen") { model.insertText(" ") }
            KeyButton(systemImage: "delete.left", width: 50, action: model.deleteBackward)
            KeyButton(systemImage: "return", width: 50) { model.insertText("\n") }
        }
        .frame(height: 42)
    }

    private func hint(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(text)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .padding()
    }

    private func insert(_ item: ClipItem) {
        model.insertText(item.text)
        store.markUsed(item)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.1)) { flashedID = item.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { if flashedID == item.id { flashedID = nil } }
        }
    }

    /// Requires Full Access – otherwise iOS doesn't let keyboards read the clipboard.
    private func saveClipboard() {
        guard let text = UIPasteboard.general.string, store.add(text) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        tab = .history
    }
}

private struct KeyButton: View {
    var systemImage: String?
    var title: String?
    var width: CGFloat?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage) }
                if let title { Text(title).lineLimit(1) }
            }
            .font(.callout)
            .frame(minWidth: width, maxWidth: width ?? .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(uiColor: .secondarySystemBackground)))
            .shadow(color: .black.opacity(0.2), radius: 0, y: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
