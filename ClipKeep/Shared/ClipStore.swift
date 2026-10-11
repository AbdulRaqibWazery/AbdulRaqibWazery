import Foundation

/// Persists clips as JSON in the App Group container.
/// The app and the keyboard each own an instance and reload before every change,
/// so edits from the other process are picked up.
@MainActor
final class ClipStore: ObservableObject {
    /// Unpinned entries beyond this count are removed (oldest first). Pinned entries are never removed.
    static let historyLimit = 200

    @Published private(set) var items: [ClipItem] = []

    private let fileURL: URL

    init(fileURL: URL = AppGroup.containerURL.appendingPathComponent("clips.json")) {
        self.fileURL = fileURL
        reload()
    }

    var pinned: [ClipItem] { items.filter(\.isPinned) }
    var history: [ClipItem] { items.filter { !$0.isPinned } }

    func reload() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data)
        else { return }
        items = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    /// Adds a new clip. If the same text already exists it is moved to the top instead.
    /// Returns `false` for empty / whitespace-only text.
    @discardableResult
    func add(_ text: String, title: String? = nil, pinned: Bool = false) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        reload()
        let title = title.flatMap { $0.isEmpty ? nil : $0 }
        if let index = items.firstIndex(where: { $0.text == text }) {
            items[index].createdAt = Date()
            items[index].isPinned = items[index].isPinned || pinned
            if let title { items[index].title = title }
        } else {
            items.append(ClipItem(text: text, title: title, isPinned: pinned))
        }
        commit()
        return true
    }

    func update(_ item: ClipItem) {
        reload()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        commit()
    }

    func togglePin(_ item: ClipItem) {
        reload()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        commit()
    }

    func markUsed(_ item: ClipItem) {
        reload()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].useCount += 1
        items[index].lastUsedAt = Date()
        commit()
    }

    func delete(_ item: ClipItem) {
        reload()
        items.removeAll { $0.id == item.id }
        commit()
    }

    /// Removes all unpinned entries.
    func clearHistory() {
        reload()
        items.removeAll { !$0.isPinned }
        commit()
    }

    private func commit() {
        items.sort { $0.createdAt > $1.createdAt }
        let overflow = Set(history.dropFirst(Self.historyLimit).map(\.id))
        if !overflow.isEmpty {
            items.removeAll { overflow.contains($0.id) }
        }
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print("ClipStore: saving failed – \(error)")
        }
    }
}
