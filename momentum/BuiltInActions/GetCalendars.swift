extension BuiltInActions {
    func getCalendars(withCalendarProvider calendarProvider: CalendarProvider) -> Action {
        return .init(
            identifier: "get_calendars",
            description: "Gets all of the user's calendars.",
            inputs: [ ],
            output: .init(
                type: .array(
                    of: .dict([
                        "id": .string,
                        "title": .string,
                        "canAddEvents": .bool,
                        "canEditEvents": .bool,
                        "canReadEvents": .bool
                    ])
                ),
                description: "Data about all of the user's calendars, including their ID, title, and access control information"
            ),
            displayTitle: "Get Calendars",
            defaultProgressDescription: "Getting Calendars...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let result = try! await calendarProvider.getCalendars()
                
                return result.map { calendar in
                    return [
                        "id": calendar.id,
                        "title": calendar.title,
                        "canAddEvents": calendar.canAddEvents,
                        "canEditEvents": calendar.canEditEvents,
                        "canReadEvents": calendar.canReadEvents
                    ]
                }
            }
        )
    }
}

