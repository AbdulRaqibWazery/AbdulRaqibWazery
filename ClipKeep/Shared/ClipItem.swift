import Foundation

struct ClipItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var title: String?
    var isPinned = false
    var createdAt = Date()
    var lastUsedAt: Date?
    var useCount = 0

    /// Title if set, otherwise the first line of the text.
    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? text
        return firstLine.trimmingCharacters(in: .whitespaces)
    }
}
