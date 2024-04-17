import Foundation

extension BuiltInActions {
    func createEvent(withCalendarProvider calendarProvider: CalendarProvider) -> Action {
        return .init(
            identifier: "create_event",
            description: "Creates a new calendar event.",
            inputs: [
                .init(type: .string, displayTitle: "Calendar ID", identifier: "calendarID", description: "The ID of the calendar to create the event in."),
                .init(type: .string, displayTitle: "Title", identifier: "title", description: "The title of the event."),
                .init(type: .string, displayTitle: "Start Date", identifier: "startDate", description: "The start date of the event, formatted in ISO 8601 yyyy-MM-dd'T'HH:mm:ss form (e.g. 2024-05-09T9:41:00)."),
                .init(type: .string, displayTitle: "End Date", identifier: "endDate", description: "The end date of the event, formatted in ISO 8601 yyyy-MM-dd'T'HH:mm:ss form (e.g. 2024-05-09T9:41:00)."),
                .init(type: .bool, displayTitle: "Is All Day", identifier: "isAllDay", description: "Indicates whether the event is an all-day event."),
                .init(type: .optional(of: .string), displayTitle: "Location", identifier: "location", description: "The location of the event."),
                .init(type: .optional(of: .string), displayTitle: "Notes", identifier: "notes", description: "Additional notes for the event.")
            ],
            output: .init(
                type: .string,
                description: "The ID of the newly created event if the event has been successfully created and an error string otherwise."
            ),
            displayTitle: "Create Event",
            defaultProgressDescription: "Creating Event...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let calendarID = parameters.inputs[0] as! String
                let title = parameters.inputs[1] as! String
                let startDate = parameters.inputs[2] as! String
                let endDate = parameters.inputs[3] as! String
                let isAllDay = parameters.inputs[4] as? Bool ?? false
                let location = parameters.inputs[5] as? String
                let notes = parameters.inputs[6] as? String
                
                guard let convertedStartDate = computeDateFromString(startDate) else {
                    return "Error: Provided date \(startDate) does not follow format."
                }
                guard let convertedEndDate = computeDateFromString(endDate) else {
                    return "Error: Provided date \(startDate) does not follow format."
                }
                
                let calendars = try! await calendarProvider.getCalendars()
                guard let calendar = calendars.first(where: { calendar in
                    calendar.id == calendarID
                }) else {
                    return "Error: Calendar with specified ID not found."
                }
                
                let id = UUID().uuidString
                let event = CalendarEvent(id: UUID().uuidString, calendar: calendar, title: title, startDate: convertedStartDate, endDate: convertedEndDate, isAllDay: isAllDay, location: location, notes: notes, isRecurring: false, recurrenceRules: [])
                let createdEvent = try! await calendarProvider.createEvent(with: event)
                
                return "Success: \(id)"
            }
        )
    }
}
