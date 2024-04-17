import Foundation

extension BuiltInActions {
    func updateEvent(withCalendarProvider calendarProvider: CalendarProvider) -> Action {
        return .init(
            identifier: "update_event",
            description: "Updates an existing calendar event.",
            inputs: [
                .init(type: .string, displayTitle: "Event ID", identifier: "eventID", description: "The ID of the event to update."),
                .init(type: .string, displayTitle: "Title", identifier: "title", description: "The updated title of the event."),
                .init(type: .string, displayTitle: "Start Date", identifier: "startDate", description: "The updated start date of the event, formatted in ISO 8601 yyyy-MM-dd'T'HH:mm:ss form (e.g. 2024-05-09T9:41:00)."),
                .init(type: .string, displayTitle: "End Date", identifier: "endDate", description: "The updated end date of the event, formatted in ISO 8601 yyyy-MM-dd'T'HH:mm:ss form (e.g. 2024-05-09T9:41:00)."),
                .init(type: .bool, displayTitle: "Is All Day", identifier: "isAllDay", description: "Indicates whether the event is an all-day event."),
                .init(type: .optional(of: .string), displayTitle: "Location", identifier: "location", description: "The updated location of the event."),
                .init(type: .optional(of: .string), displayTitle: "Notes", identifier: "notes", description: "The updated notes for the event."),
                .init(type: .optional(of: .string), displayTitle: "Recurrence Editing Scope", identifier: "recurrenceEditingScope", description: "The recurrence editing scope for updating recurring events. Possible values: 'onlyThis', 'thisAndFuture'. Leave blank for non-recurring events.")
            ],
            output: .init(
                type: .string,
                description: "A message indicating the success or failure of the event update. If the update is successful, it returns 'Success'. Otherwise, it returns an error string."
            ),
            displayTitle: "Update Event",
            defaultProgressDescription: "Updating Event...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let eventID = parameters.inputs[0] as! String
                let title = parameters.inputs[1] as! String
                let startDate = parameters.inputs[2] as! String
                let endDate = parameters.inputs[3] as! String
                let isAllDay = parameters.inputs[4] as! Bool
                let location = parameters.inputs[5] as? String
                let notes = parameters.inputs[6] as? String
                let recurrenceEditingScope = parameters.inputs[7] as? String
                
                guard let convertedStartDate = computeDateFromString(startDate) else {
                    return "Error: Provided start date \(startDate) does not follow the expected format."
                }
                guard let convertedEndDate = computeDateFromString(endDate) else {
                    return "Error: Provided end date \(endDate) does not follow the expected format."
                }
                
                guard let calendar = try? await calendarProvider.getEvent(with: eventID)?.calendar else {
                    return "Error: Event with specified ID not found."
                }
                
                let updatedEvent = CalendarEvent(
                    id: eventID,
                    calendar: calendar,
                    title: title,
                    startDate: convertedStartDate,
                    endDate: convertedEndDate,
                    isAllDay: isAllDay,
                    location: location,
                    notes: notes,
                    isRecurring: false,
                    recurrenceRules: []
                )
                
                let recurrenceEditingScopeValue: RecurringEventEditScope?
                if let recurrenceEditingScope = recurrenceEditingScope {
                    switch recurrenceEditingScope {
                    case "onlyThis":
                        recurrenceEditingScopeValue = .onlyThis
                    case "thisAndFuture":
                        recurrenceEditingScopeValue = .thisAndFuture
                    default:
                        recurrenceEditingScopeValue = nil
                    }
                } else {
                    recurrenceEditingScopeValue = nil
                }
                
                do {
                    _ = try await calendarProvider.updateEvent(with: updatedEvent, recurrenceEditingScope: recurrenceEditingScopeValue)
                    return "Success"
                } catch {
                    return "Error: \(error.localizedDescription)"
                }
            }
        )
    }
}
