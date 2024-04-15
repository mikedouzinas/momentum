//
//  AppleReminderProvider.swift
//  momentum
//
//  Created by Mike Veson on 4/15/24.
//

import Foundation
import EventKit

class AppleReminderProvider: TodoProvider {
    private let eventStore = EKEventStore()

    func getTodoSources() async throws -> [TodoSource] {
        try await requestAccessIfNeeded()
        return eventStore.calendars(for: .reminder).map { calendar in
            TodoSource(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                canAddTodos: calendar.allowsContentModifications,
                canEditTodos: calendar.allowsContentModifications,
                canDeleteTodos: calendar.allowsContentModifications,
                canReadTodos: true,
                color: calendar.cgColor
            )
        }
    }

    func getDefaultTodoSource() async throws -> TodoSource {
        try await requestAccessIfNeeded()
        guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
            throw NSError(domain: "AppleReminderProvider", code: 0, userInfo: [NSLocalizedDescriptionKey: "No default todo source available"])
        }
        return TodoSource(
            id: defaultCalendar.calendarIdentifier,
            title: defaultCalendar.title,
            canAddTodos: defaultCalendar.allowsContentModifications,
            canEditTodos: defaultCalendar.allowsContentModifications,
            canDeleteTodos: defaultCalendar.allowsContentModifications,
            canReadTodos: true,
            color: defaultCalendar.cgColor
        )
    }

    func getTodos(for source: TodoSource) async throws -> [Todo] {
        try await requestAccessIfNeeded()
        let predicate = eventStore.predicateForReminders(in: [eventStore.calendar(withIdentifier: source.id)!])

        let reminders = try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { fetchedReminders in
                if let reminders = fetchedReminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppleReminderProvider", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch reminders"]))
                }
            }
        }

        return reminders.map { reminder in
            Todo(
                id: reminder.calendarItemIdentifier,
                source: source,
                title: reminder.title,
                description: reminder.notes ?? "",
                completed: reminder.isCompleted,
                doDate: reminder.startDateComponents?.date,
                deadline: reminder.dueDateComponents?.date
            )
        }
    }


    func createTodo(for source: TodoSource) async throws -> Todo {
        try await requestAccessIfNeeded()
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = eventStore.calendar(withIdentifier: source.id)
        try eventStore.save(reminder, commit: true)
        return Todo(
            id: reminder.calendarItemIdentifier,
            source: source,
            title: reminder.title,
            description: reminder.notes ?? "",
            completed: reminder.isCompleted,
            doDate: reminder.startDateComponents?.date,
            deadline: reminder.dueDateComponents?.date
        )
    }

    func updateTodo(todo: Todo) async throws -> Todo {
        try await requestAccessIfNeeded()
        guard let reminder = eventStore.calendarItem(withIdentifier: todo.id) as? EKReminder else {
            throw NSError(domain: "AppleReminderProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Todo not found"])
        }
        reminder.title = todo.title
        reminder.notes = todo.description
        reminder.isCompleted = todo.completed
        if let doDate = todo.doDate {
            reminder.startDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: doDate)
        }
        if let deadline = todo.deadline {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: deadline)
        }
        try eventStore.save(reminder, commit: true)
        return todo
    }

    func deleteTodo(in source: TodoSource, id: String) async throws {
        try await requestAccessIfNeeded()
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw NSError(domain: "AppleReminderProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Todo not found"])
        }
        try eventStore.remove(reminder, commit: true)
    }

    // Helper function to ensure the app has the necessary permissions
    private func requestAccessIfNeeded() async throws {
        let status = await EKEventStore.authorizationStatus(for: .reminder)
        if status == .notDetermined || status == .denied {
            let (granted, error) = await eventStore.requestAccess(to: .reminder)
            if !granted || error != nil {
                throw NSError(domain: "AppleReminderProvider", code: 3, userInfo: [NSLocalizedDescriptionKey: "Access to reminders is denied or not determined"])
            }
        }
    }
}
