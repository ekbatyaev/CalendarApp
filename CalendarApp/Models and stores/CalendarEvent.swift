import Foundation

struct CalendarEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let date: Date
    let time: String?
    let isAllDay: Bool
    let description: String
    let isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: String?,
        isAllDay: Bool,
        description: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.isAllDay = isAllDay
        self.description = description
        self.isCompleted = isCompleted
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case time
        case isAllDay
        case description
        case isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(Date.self, forKey: .date)
        self.time = try container.decodeIfPresent(String.self, forKey: .time)
        self.isAllDay = try container.decode(Bool.self, forKey: .isAllDay)
        self.description = try container.decode(String.self, forKey: .description)
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }
}
