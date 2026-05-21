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
    
    func toggleCompleted(id: UUID) {
        guard let index = events.firstIndex(where: { $0.id == id }) else {
            return
        }

        let event = events[index]

        events[index] = CalendarEvent(
            id: event.id,
            title: event.title,
            date: event.date,
            time: event.time,
            isAllDay: event.isAllDay,
            description: event.description,
            isCompleted: !event.isCompleted
        )

        sortEvents()
        save()
    }

    func setCompleted(id: UUID, isCompleted: Bool) {
        guard let index = events.firstIndex(where: { $0.id == id }) else {
            return
        }

        let event = events[index]

        events[index] = CalendarEvent(
            id: event.id,
            title: event.title,
            date: event.date,
            time: event.time,
            isAllDay: event.isAllDay,
            description: event.description,
            isCompleted: isCompleted
        )

        sortEvents()
        save()
    }
    

    private func sortEvents() {
        events.sort { first, second in
            let firstDay = Calendar.current.startOfDay(for: first.date)
            let secondDay = Calendar.current.startOfDay(for: second.date)

            if firstDay != secondDay {
                return firstDay < secondDay
            }

            if first.isCompleted != second.isCompleted {
                return !first.isCompleted && second.isCompleted
            }

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
