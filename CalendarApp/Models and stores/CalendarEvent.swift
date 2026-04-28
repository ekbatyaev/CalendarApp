import Foundation

struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let time: String?
    let isAllDay: Bool
    let description: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: String?,
        isAllDay: Bool,
        description: String
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.isAllDay = isAllDay
        self.description = description
    }
}
