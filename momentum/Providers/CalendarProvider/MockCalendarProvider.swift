import Foundation
import CoreGraphics

class MockCalendarProvider: CalendarProvider {
    var calendars = MockCalendarProvider.getMockCalendarData()
    var events = MockCalendarProvider.getMockEvents()
    
    func getCalendars() async throws -> [AppCalendar] {
        return calendars
    }
    
    func getDefaultCalendar() async -> AppCalendar {
        return calendars[0]
    }
    
    func getEvents(for calendar: AppCalendar, startDate: Date, endDate: Date, limit: Int?) async throws -> [CalendarEvent] {
        var filteredEvents = events.filter { event in
            event.calendar.id == calendar.id &&
            event.startDate >= startDate &&
            event.endDate <= endDate
        }
        
        filteredEvents.sort()
        
        if let limit = limit, filteredEvents.count > limit {
            return Array(filteredEvents.prefix(limit))
        } else {
            return filteredEvents
        }
    }
    
    func getEvent(with id: String) async throws -> CalendarEvent? {
        return events.first(where: { $0.id == id })
    }
    
    func createEvent(with event: CalendarEvent) async throws -> CalendarEvent {
        events.append(event)
        return event
    }
    
    func updateEvent(with newEvent: CalendarEvent, recurrenceEditingScope: RecurringEventEditScope?) async throws -> CalendarEvent {
        if let index = events.firstIndex(where: { $0.id == newEvent.id }) {
            events[index] = newEvent
            return events[index]
        }
        throw NSError(domain: "EventNotFound", code: 404, userInfo: nil)
    }
    
    func deleteEvent(in calendar: AppCalendar, id: String) async throws {
        if let index = events.firstIndex(where: { $0.id == id && $0.calendar.id == calendar.id }) {
            events.remove(at: index)
        } else {
            throw NSError(domain: "EventNotFound", code: 404, userInfo: nil)
        }
    }
}

extension MockCalendarProvider {
    static func getMockCalendarData() -> [AppCalendar] {
        return [
            .init(id: "1", title: "Work", canAddEvents: true, canEditEvents: true, canDeleteEvents: false, canReadEvents: true, color: CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)),
            .init(id: "2", title: "Personal", canAddEvents: true, canEditEvents: true, canDeleteEvents: true, canReadEvents: true, color: CGColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1.0)),
            .init(id: "3", title: "Family", canAddEvents: true, canEditEvents: false, canDeleteEvents: false, canReadEvents: true, color: CGColor(red: 0.4, green: 0.8, blue: 0.2, alpha: 1.0)),
            .init(id: "4", title: "Holidays", canAddEvents: false, canEditEvents: false, canDeleteEvents: false, canReadEvents: true, color: CGColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)),
            .init(id: "5", title: "Birthdays", canAddEvents: false, canEditEvents: false, canDeleteEvents: false, canReadEvents: true, color: CGColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0))
        ]
    }

    static func getMockEvents() -> [CalendarEvent] {
        let currentDate = Date()
        let calendarData = getMockCalendarData()
        
        return [
            // Work events
            .init(id: "E1", calendar: calendarData[0], title: "Weekly Team Sync", startDate: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E2", calendar: calendarData[0], title: "Project Deadline", startDate: Calendar.current.date(byAdding: .day, value: 3, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 3, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E3", calendar: calendarData[0], title: "Client Presentation", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E10", calendar: calendarData[0], title: "Budget Review Meeting", startDate: Calendar.current.date(byAdding: .day, value: 8, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 8, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E11", calendar: calendarData[0], title: "Quarterly Strategy Planning", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 4, to: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E12", calendar: calendarData[0], title: "HR Training Session", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),

            // Personal events
            .init(id: "E4", calendar: calendarData[1], title: "Dentist Appointment", startDate: Calendar.current.date(byAdding: .day, value: 4, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 4, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E5", calendar: calendarData[1], title: "Gym Session", startDate: Calendar.current.date(byAdding: .day, value: 6, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 6, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E6", calendar: calendarData[1], title: "Coffee with Sam", startDate: Calendar.current.date(byAdding: .day, value: 10, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 10, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E13", calendar: calendarData[1], title: "Book Club Meeting", startDate: Calendar.current.date(byAdding: .day, value: 12, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 12, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E14", calendar: calendarData[1], title: "Shopping with Emily", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E15", calendar: calendarData[1], title: "Piano Lessons", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),

            // Family events
            .init(id: "E7", calendar: calendarData[2], title: "Family Game Night", startDate: Calendar.current.date(byAdding: .day, value: 8, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 4, to: Calendar.current.date(byAdding: .day, value: 8, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E8", calendar: calendarData[2], title: "Visit Grandma", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: currentDate)!, endDate: Calendar.current.date(byAdding: .hour, value: 5, to: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: currentDate)!)!, isAllDay: false, isRecurring: false, recurrenceRules: []),
            .init(id: "E9", calendar: calendarData[2], title: "Sibling's Graduation", startDate: Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!, endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!)!, isAllDay: true, isRecurring: false, recurrenceRules: []),
            
            .init(id: "E4", calendar: calendarData[3], title: "New Year's Day", startDate: Calendar.current.date(byAdding: .month, value: 2, to: currentDate)!, endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .month, value: 2, to: currentDate)!)!, isAllDay: true, isRecurring: false, recurrenceRules: []),
            .init(id: "E5", calendar: calendarData[4], title: "Alice's Birthday", startDate: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: currentDate)!, endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: currentDate)!)!, isAllDay: true, isRecurring: false, recurrenceRules: [])
        ]
    }
}
