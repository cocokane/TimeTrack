import Foundation
import SwiftUI

struct Tag: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var lastUsed: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0,
        lastUsed: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.lastUsed = lastUsed
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortOrder = "sort_order"
        case lastUsed = "last_used"
        case createdAt = "created_at"
    }
}

struct TagsFile: Codable {
    var tags: [Tag]
}
