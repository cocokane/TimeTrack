import Foundation

struct Session: Identifiable, Codable, Equatable {
    var id: UUID
    var start: Date
    var end: Date?
    var durationSeconds: Int
    var tag: String
    var description: String
    var remarks: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        start: Date = Date(),
        end: Date? = nil,
        durationSeconds: Int = 0,
        tag: String,
        description: String = "",
        remarks: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.durationSeconds = durationSeconds
        self.tag = tag
        self.description = description
        self.remarks = remarks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isActive: Bool {
        end == nil
    }

    var duration: TimeInterval {
        if let end = end {
            return end.timeIntervalSince(start)
        }
        return Date().timeIntervalSince(start)
    }

    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let startStr = formatter.string(from: start)
        if let end = end {
            let endStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)"
        }
        return "\(startStr) - now"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case start
        case end
        case durationSeconds = "duration_seconds"
        case tag
        case description
        case remarks
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
