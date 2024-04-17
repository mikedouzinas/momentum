import EventKit
import Foundation

class AppleReminderProvider: TodoProvider {
    private let eventStore = EKEventStore()

    func getTodoSources() async throws -> [TodoSource] {
        requestRemindersAccessIfNeeded { granted, error in
            if !granted {
                print("Access to Reminders denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
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
        requestRemindersAccessIfNeeded { granted, error in
            if !granted {
                print("Access to Reminders denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
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
        requestRemindersAccessIfNeeded { granted, error in
            if !granted {
                print("Access to Reminders denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
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


    func createTodo(for source: TodoSource, todo: Todo) async throws -> Todo {
        requestRemindersAccessIfNeeded { granted, error in
            if !granted {
                print("Access to Reminders denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
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
        requestRemindersAccessIfNeeded { granted, error in
            if !granted {
                print("Access to Reminders denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
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
        requestRemindersAccessIfNeeded { granted, error in
            if !granted {
                print("Access to Reminders denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw NSError(domain: "AppleReminderProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Todo not found"])
        }
        try eventStore.remove(reminder, commit: true)
    }

    func requestRemindersAccessIfNeeded(completion: @escaping (Bool, Error?) -> Void) {
        // Check the current authorization status
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .authorized:
            // Access has already been granted
            completion(true, nil)
        case .notDetermined:
            // Request access if the status is not determined
            eventStore.requestFullAccessToReminders { (granted, error) in
                DispatchQueue.main.async {
                    completion(granted, error)
                }
            }
        default:
            // Access denied or restricted
            completion(false, nil)
        }
    }
}
