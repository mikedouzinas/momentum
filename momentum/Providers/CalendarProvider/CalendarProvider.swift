import Foundation

/// Represents a calendar in the user's calendar system.
struct Calendar: Identifiable {
    let id: String
    let title: String
    let canAddEvents: Bool
    let canEditEvents: Bool
    let canDeleteEvents: Bool
    let canReadEvents: Bool
    let color: CGColor
}

struct RecurrenceRule {
    enum RecurrenceFrequency {
        case daily
        case weekly
        case monthly
        case yearly
    }

    struct DayOfWeek {
        let dayOfTheWeek: Int // 1 = Sunday, 2 = Monday, etc.
        let weekNumber: Int // 1 = First week, 2 = Second week, etc.
    }
    let frequency: RecurrenceFrequency
    let interval: Int
    let daysOfTheWeek: [DayOfWeek]?
    let daysOfTheMonth: [Int]?
    let weeksOfTheYear: [Int]?
    let daysOfTheYear: [Int]?
    let setPositions: [Int]?
    let endDate: Date?
}

struct CalendarEvent: Identifiable {
    let id: String
    let calendar: Calendar

    var title: String
    var timeZone: TimeZone?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var location: String?
    var notes: String?

    // Recurrences
    var isRecurring: Bool
    var recurrenceOriginalDate: Date!
    var recurrenceEndDate: Date!
    var recurrenceIsDetached: Bool! // indicates if the event has been modified from the original recurring event
    var recurrenceRules: [RecurrenceRule]
    
    // TODO: Alarms. Not supported in this version yet.

    // Attendees, Guests, Accepting events, etc. are not supported. 
}

enum RecurringEventEditScope {
    case thisAndFuture
    case onlyThis
}

protocol CalendarProvider {
    func getCalendars() -> [Calendar]
    func getDefaultCalendar() -> Calendar
    func getEvents(for calendar: Calendar, startDate: Date, endDate: Date, limit: Int?) -> [CalendarEvent]
    func getEvent(with id: String) -> CalendarEvent?
    func createEvent(with event: CalendarEvent) -> CalendarEvent
    func updateEvent(with event: CalendarEvent, recurrenceEditingScope: RecurringEventEditScope?) -> CalendarEvent
    func deleteEvent(with id: String)
}