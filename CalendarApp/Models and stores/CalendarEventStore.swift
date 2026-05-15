import Foundation

actor CalendarEventStore {

    private var events: [CalendarEvent] = []

    private var fileURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        return documents.appendingPathComponent("calendar_events.json")
    }

    init() {
        load()
    }

    func add(_ event: CalendarEvent) {
        events.append(event)
        sortEvents()
        save()
    }
    
    func delete(_ event: CalendarEvent) {
        delete(id: event.id)
    }

    func delete(id: UUID) {
        events.removeAll { event in
            event.id == id
        }

        save()
    }
    

    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current

        return events.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    func allEvents() -> [CalendarEvent] {
        events
    }

    func clear() {
        events.removeAll()
        save()
    }

    private func sortEvents() {
        events.sort { first, second in
            if first.isAllDay != second.isAllDay {
                return first.isAllDay && !second.isAllDay
            }

            return (first.time ?? "") < (second.time ?? "")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            events = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            events = try decoder.decode([CalendarEvent].self, from: data)
            sortEvents()
            save()
        } catch {
            print("Ошибка чтения calendar_events.json:", error)
            events = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Ошибка сохранения calendar_events.json:", error)
        }
    }
}
