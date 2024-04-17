import Foundation

extension BuiltInActions {
    func deleteTodo(withTodoProvider todoProvider: TodoProvider) -> Action {
        return .init(
            identifier: "delete_todo",
            description: "Deletes an existing todo.",
            inputs: [
                .init(type: .string, displayTitle: "Todo ID", identifier: "todoID", description: "The ID of the todo to delete.")
            ],
            output: .init(
                type: .string,
                description: "A message indicating the success or failure of the todo deletion. If the deletion is successful, it returns 'Success'. Otherwise, it returns an error string."
            ),
            displayTitle: "Delete Todo",
            defaultProgressDescription: "Deleting Todo...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let todoID = parameters.inputs[0] as! String
                
                guard let todo = try? await todoProvider.getTodos(for: TodoSource(id: "", title: "", canAddTodos: false, canEditTodos: false, canDeleteTodos: false, canReadTodos: false, color: nil)).first(where: { $0.id == todoID }) else {
                    return "Error: Todo with specified ID not found."
                }
                
                do {
                    try await todoProvider.deleteTodo(in: todo.source, id: todoID)
                    return "Success"
                } catch {
                    return "Error: \(error.localizedDescription)"
                }
            }
        )
    }
}
