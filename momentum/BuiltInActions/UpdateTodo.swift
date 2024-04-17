import Foundation

extension BuiltInActions {
    func updateTodo(withTodoProvider todoProvider: TodoProvider) -> Action {
        return .init(
            identifier: "update_todo",
            description: "Updates an existing todo.",
            inputs: [
                .init(type: .string, displayTitle: "Todo ID", identifier: "todoID", description: "The ID of the todo to update."),
                .init(type: .string, displayTitle: "Title", identifier: "title", description: "The updated title of the todo."),
                .init(type: .string, displayTitle: "Description", identifier: "description", description: "The updated description of the todo."),
                .init(type: .bool, displayTitle: "Completed", identifier: "completed", description: "The updated completion status of the todo."),
                .init(type: .optional(of: .string), displayTitle: "Do Date", identifier: "doDate", description: "The updated date when the todo should be done, formatted as yyyy-MM-dd'T'HH:mm:ss (e.g. 2024-05-09T9:41:00)."),
                .init(type: .optional(of: .string), displayTitle: "Deadline", identifier: "deadline", description: "The updated deadline date for the todo, formatted as yyyy-MM-dd'T'HH:mm:ss (e.g. 2024-05-09T9:41:00).")
            ],
            output: .init(
                type: .string,
                description: "A message indicating the success or failure of the todo update. If the update is successful, it returns 'Success'. Otherwise, it returns an error string."
            ),
            displayTitle: "Update Todo",
            defaultProgressDescription: "Updating Todo...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let todoID = parameters.inputs[0] as! String
                let title = parameters.inputs[1] as! String
                let description = parameters.inputs[2] as! String
                let completed = parameters.inputs[3] as! Bool
                let doDateString = parameters.inputs[4] as? String
                let deadlineString = parameters.inputs[5] as? String
                
                guard let todo = try? await todoProvider.getTodos(for: TodoSource(id: "", title: "", canAddTodos: false, canEditTodos: false, canDeleteTodos: false, canReadTodos: false, color: nil)).first(where: { $0.id == todoID }) else {
                    return "Error: Todo with specified ID not found."
                }
                
                let updatedDoDate = doDateString.flatMap { computeDateFromString($0) }
                let updatedDeadline = deadlineString.flatMap { computeDateFromString($0) }
                
                let updatedTodo = Todo(id: todo.id, source: todo.source, title: title, description: description, completed: completed, doDate: updatedDoDate, deadline: updatedDeadline)
                
                do {
                    _ = try await todoProvider.updateTodo(todo: updatedTodo)
                    return "Success"
                } catch {
                    return "Error: \(error.localizedDescription)"
                }
            }
        )
    }
}
