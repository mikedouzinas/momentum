//
//  AppleCalendarProvider.swift
//  momentum
//
//  Created by Mike Veson on 4/11/24.
//

import Foundation
import EventKit

class AppleCalendarProvider: CalendarProvider {
    private let eventStore = EKEventStore()

    func getCalendars() async throws -> [Calendar] {
        try await requestAccessIfNeeded()
        return eventStore.calendars(for: .event).map { ekCalendar in
            Calendar(
                id: ekCalendar.calendarIdentifier,
                title: ekCalendar.title,
                canAddEvents: ekCalendar.allowsContentModifications,
                canEditEvents: ekCalendar.allowsContentModifications,
                canDeleteEvents: ekCalendar.allowsContentModifications,
                canReadEvents: true, // EventKit does not provide a direct property for reading permissions.
                color: ekCalendar.cgColor
            )
        }
    }

    func getDefaultCalendar() async -> Calendar {
        try await requestAccessIfNeeded()
        let defaultCalendar = eventStore.defaultCalendarForNewEvents!
        return Calendar(
            id: defaultCalendar.calendarIdentifier,
            title: defaultCalendar.title,
            canAddEvents: defaultCalendar.allowsContentModifications,
            canEditEvents: defaultCalendar.allowsContentModifications,
            canDeleteEvents: defaultCalendar.allowsContentModifications,
            canReadEvents: true,
            color: defaultCalendar.cgColor
        )
    }

    func getEvents(for calendar: Calendar, startDate: Date, endDate: Date, limit: Int?) async throws -> [CalendarEvent] {
        try await requestAccessIfNeeded()
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [eventStore.calendar(withIdentifier: calendar.id)!])
        let ekEvents = eventStore.events(matching: predicate)
        let limitedEvents = limit != nil ? Array(ekEvents.prefix(limit!)) : ekEvents
        return limitedEvents.map { ekEvent in
            self.convertToCalendarEvent(ekEvent: ekEvent)
        }
    }

    func getEvent(with id: String) async throws -> CalendarEvent? {
        try await requestAccessIfNeeded()
        guard let ekEvent = eventStore.event(withIdentifier: id) else { return nil }
        return convertToCalendarEvent(ekEvent: ekEvent)
    }

    func createEvent(with event: CalendarEvent) async throws -> CalendarEvent {
        try await requestAccessIfNeeded()
        let ekEvent = EKEvent(eventStore: eventStore)
        updateEKEvent(ekEvent: ekEvent, with: event)
        try eventStore.save(ekEvent, span: .thisEvent)
        return convertToCalendarEvent(ekEvent: ekEvent)
    }

    func updateEvent(with event: CalendarEvent, recurrenceEditingScope: RecurringEventEditScope?) async throws -> CalendarEvent {
        try await requestAccessIfNeeded()
        guard let ekEvent = eventStore.event(withIdentifier: event.id) else { throw NSError(domain: "AppleCalendarProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Event not found"]) }
        updateEKEvent(ekEvent: ekEvent, with: event)
        let span: EKSpan = recurrenceEditingScope == .thisAndFuture ? .futureEvents : .thisEvent
        try eventStore.save(ekEvent, span: span)
        return convertToCalendarEvent(ekEvent: ekEvent)
    }

    func deleteEvent(in calendar: Calendar, id: String) async throws {
        try await requestAccessIfNeeded()
        guard let ekEvent = eventStore.event(withIdentifier: id) else { return }
        try eventStore.remove(ekEvent, span: .thisEvent)
    }

    // MARK: - Helper Methods

    private func convertToCalendarEvent(ekEvent: EKEvent) -> CalendarEvent {
        let calendar = Calendar(
            id: ekEvent.calendar.calendarIdentifier,
            title: ekEvent.calendar.title,
            canAddEvents: ekEvent.calendar.allowsContentModifications,
            canEditEvents: ekEvent.calendar.allowsContentModifications,
            canDeleteEvents: ekEvent.calendar.allowsContentModifications,
            canReadEvents: true, // Assumed true as EventKit does not provide direct property.
            color: ekEvent.calendar.cgColor
        )

        return CalendarEvent(
            id: ekEvent.eventIdentifier,
            calendar: calendar,
            title: ekEvent.title,
            timeZone: ekEvent.timeZone,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location,
            notes: ekEvent.notes,
            isRecurring: ekEvent.hasRecurrenceRules,
            recurrenceOriginalDate: nil, // EKEvent does not provide a direct mapping for this.
            recurrenceEndDate: ekEvent.recurrenceRules?.first?.recurrenceEnd?.endDate,
            recurrenceIsDetached: ekEvent.isDetached,
            recurrenceRules: ekEvent.recurrenceRules?.compactMap(convertToRecurrenceRule) ?? []
        )
    }

    private func convertToRecurrenceRule(ekRecurrenceRule: EKRecurrenceRule) -> RecurrenceRule? {
        let frequency: RecurrenceRule.RecurrenceFrequency
        switch ekRecurrenceRule.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        @unknown default: return nil
        }

        let daysOfTheWeek: [RecurrenceRule.DayOfWeek]? = ekRecurrenceRule.daysOfTheWeek?.compactMap { ekDay -> RecurrenceRule.DayOfWeek? in
            RecurrenceRule.DayOfWeek(dayOfTheWeek: ekDay.dayOfTheWeek.rawValue, weekNumber: ekDay.weekNumber)
        }

        let daysOfTheMonth: [Int]? = ekRecurrenceRule.daysOfTheMonth?.compactMap { $0.intValue }
        let weeksOfTheYear: [Int]? = ekRecurrenceRule.weeksOfTheYear?.compactMap { $0.intValue }
        let daysOfTheYear: [Int]? = ekRecurrenceRule.daysOfTheYear?.compactMap { $0.intValue }
        let setPositions: [Int]? = ekRecurrenceRule.setPositions?.compactMap { $0.intValue }

        let endDate = ekRecurrenceRule.recurrenceEnd?.endDate

        return RecurrenceRule(
            frequency: frequency,
            interval: ekRecurrenceRule.interval,
            daysOfTheWeek: daysOfTheWeek,
            daysOfTheMonth: daysOfTheMonth,
            weeksOfTheYear: weeksOfTheYear,
            daysOfTheYear: daysOfTheYear,
            setPositions: setPositions,
            endDate: endDate
        )
    }


    private func updateEKEvent(ekEvent: EKEvent, with calendarEvent: CalendarEvent) {
        ekEvent.title = calendarEvent.title
        ekEvent.startDate = calendarEvent.startDate
        ekEvent.endDate = calendarEvent.endDate
        ekEvent.isAllDay = calendarEvent.isAllDay
        ekEvent.location = calendarEvent.location
        ekEvent.notes = calendarEvent.notes
        ekEvent.timeZone = calendarEvent.timeZone
        ekEvent.calendar = eventStore.calendar(withIdentifier: calendarEvent.calendar.id)
        
        if calendarEvent.isRecurring {
            updateRecurrenceRules(for: ekEvent, with: calendarEvent.recurrenceRules)
        } else {
            ekEvent.recurrenceRules = nil
        }
    }
    private func updateRecurrenceRules(for ekEvent: EKEvent, with recurrenceRules: [RecurrenceRule]) {
        ekEvent.recurrenceRules = recurrenceRules.compactMap { rule -> EKRecurrenceRule? in
            let frequency: EKRecurrenceFrequency
            switch rule.frequency {
            case .daily: frequency = .daily
            case .weekly: frequency = .weekly
            case .monthly: frequency = .monthly
            case .yearly: frequency = .yearly
            }

            var ekDaysOfTheWeek: [EKRecurrenceDayOfWeek]? = nil
            if let daysOfTheWeek = rule.daysOfTheWeek {
                ekDaysOfTheWeek = daysOfTheWeek.map { EKRecurrenceDayOfWeek(dayOfTheWeek: EKWeekday(rawValue: $0.dayOfTheWeek)!, weekNumber: $0.weekNumber) }
            }

            let ekRecurrenceEnd = rule.endDate != nil ? EKRecurrenceEnd(end: rule.endDate!) : nil

            // Convert [Int]? to [NSNumber]? for the parameters expected by EKRecurrenceRule
            let ekDaysOfTheMonth = rule.daysOfTheMonth?.map(NSNumber.init)
            let ekWeeksOfTheYear = rule.weeksOfTheYear?.map(NSNumber.init)
            let ekDaysOfTheYear = rule.daysOfTheYear?.map(NSNumber.init)
            let ekSetPositions = rule.setPositions?.map(NSNumber.init)

            return EKRecurrenceRule(
                recurrenceWith: frequency,
                interval: rule.interval,
                daysOfTheWeek: ekDaysOfTheWeek,
                daysOfTheMonth: ekDaysOfTheMonth,
                monthsOfTheYear: nil, // Structure does not include monthsOfTheYear.
                weeksOfTheYear: ekWeeksOfTheYear,
                daysOfTheYear: ekDaysOfTheYear,
                setPositions: ekSetPositions,
                end: ekRecurrenceEnd
            )
        }
    }
    
    private func requestAccessIfNeeded() async throws {
        let status = await EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined || status == .denied {
            let (granted, error) = await eventStore.requestAccess(to: .event)
            if let error = error {
                throw error
            }
            guard granted else {
                throw NSError(domain: "AppleCalendarProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to calendar is denied by the user"])
            }
        }
    }
}
