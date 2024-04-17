import Foundation

extension BuiltInActions {
    func getEvents(withCalendarProvider calendarProvider: CalendarProvider) -> Action {
        return .init(
            identifier: "get_events",
            description: "Gets the user's calendar events.",
            inputs: [
                .init(type: .optional(of: .string), displayTitle: "Calendar ID", identifier: "calendarID", description: "The ID of the calendar that contains the events. Leave blank to fetch from all calendars."),
                .init(type: .optional(of: .string), displayTitle: "Start Date", identifier: "startDate", description: "The start date, formatted in ISO 8601 yyyy-MM-dd'T'HH:mm:ss form (e.g. 2024-05-09T9:41:00). Leave blank to fetch events from the current date."),
                .init(type: .optional(of: .string), displayTitle: "End Date", identifier: "endDate", description: "The end date, formatted in ISO 8601 yyyy-MM-dd'T'HH:mm:ss form (e.g. 2024-05-09T9:41:00). Leave blank to fetch all near-future events."),
                .init(type: .optional(of: .int), displayTitle: "Limit", identifier: "limit", description: "The maximum number of events to fetch. Leave blank to default to 20 events."),
                
            ],
            output: .init(
                type: .array(
                    of: .dict([
                        "id": .string,
                        "title": .string,
                        "calendarID": .string,
                        "startDate": .string,
                        "endDate": .string,
                        "isAllDay": .bool,
                        "location": .optional(of: .string),
                        "notes": .optional(of: .string)
                    ])
                ),
                description: "Data about all of the events matching the query, including their ID, the calendar to which they belonged to, their start and end date, location, etc."
            ),
            displayTitle: "Get Events",
            defaultProgressDescription: "Getting Events...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let calendarID = parameters.inputs[0] as? String
                let startDate = parameters.inputs[1] as? String
                let endDate = parameters.inputs[2] as? String
                let limit = (parameters.inputs[3] as? Int) ?? 20
                
                let convertedStartDate: Date
                if let startDate = startDate {
                    convertedStartDate = computeDateFromString(startDate) ?? .now
                } else {
                    convertedStartDate = .now
                }
                
                let convertedEndDate: Date
                if let endDate = endDate {
                    convertedEndDate = computeDateFromString(endDate) ?? .distantFuture
                } else {
                    convertedEndDate = .distantFuture
                }
                
                var events: [CalendarEvent] = []
                if let calendarID = calendarID {
                    let calendars = try! await calendarProvider.getCalendars()
                    guard let calendar = calendars.first(where: { calendar in
                        calendar.id == calendarID
                    }) else {
                        return "Error: Calendar with specified ID not found."
                    }
                    events = try! await calendarProvider.getEvents(for: calendar, startDate: convertedStartDate, endDate: convertedEndDate, limit: limit)
                } else {
                    events = try! await calendarProvider.getAllEvents(startDate: convertedStartDate, endDate: convertedEndDate, limit: limit)
                }
                
                return events.map { calendarEvent in
                    return [
                        "id": calendarEvent.id,
                        "title": calendarEvent.title,
                        "calendarID": calendarEvent.calendar.id,
                        "startDate": getDateString(forDate: calendarEvent.startDate),
                        "endDate": getDateString(forDate: calendarEvent.endDate),
                        "isAllDay": calendarEvent.isAllDay,
                        "location": calendarEvent.location,
                        "notes": calendarEvent.notes
                    ] as [String: Any?]
                }
            }
        )
    }
}

