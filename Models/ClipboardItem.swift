import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
    }

    var preview: String {
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first ?? ""
        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "..."
        }
        return firstLine
    }

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}