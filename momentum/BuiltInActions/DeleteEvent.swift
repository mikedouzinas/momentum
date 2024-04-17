import Foundation

extension BuiltInActions {
    func deleteEvent(withCalendarProvider calendarProvider: CalendarProvider) -> Action {
        return .init(
            identifier: "delete_event",
            description: "Deletes an existing calendar event.",
            inputs: [
                .init(type: .string, displayTitle: "Event ID", identifier: "eventID", description: "The ID of the event to delete.")
            ],
            output: .init(
                type: .string,
                description: "A message indicating the success or failure of the event deletion. If the deletion is successful, it returns 'Success'. Otherwise, it returns an error string."
            ),
            displayTitle: "Delete Event",
            defaultProgressDescription: "Deleting Event...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let eventID = parameters.inputs[0] as! String
                
                guard let event = try? await calendarProvider.getEvent(with: eventID) else {
                    return "Error: Event with specified ID not found."
                }
                
                do {
                    try await calendarProvider.deleteEvent(in: event.calendar, id: eventID)
                    return "Success"
                } catch {
                    return "Error: \(error.localizedDescription)"
                }
            }
        )
    }
}
