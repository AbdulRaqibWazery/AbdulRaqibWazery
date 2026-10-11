import SwiftUI

struct ClipRow: View {
    let item: ClipItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(item.displayTitle)
                    .font(.body.weight(item.title?.isEmpty == false ? .semibold : .regular))
                    .lineLimit(1)
            }
            if item.title?.isEmpty == false || item.text.contains(where: \.isNewline) {
                Text(item.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(item.createdAt, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
