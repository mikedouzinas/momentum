import Foundation

extension BuiltInActions {
    func getTodos(withTodoProvider todoProvider: TodoProvider) -> Action {
        return .init(
            identifier: "get_todos",
            description: "Gets the user's todos from a specific todo source.",
            inputs: [
                .init(type: .string, displayTitle: "Source ID", identifier: "sourceID", description: "The ID of the todo source to fetch todos from.")
            ],
            output: .init(
                type: .array(
                    of: .dict([
                        "id": .string,
                        "sourceID": .string,
                        "title": .string,
                        "description": .string,
                        "completed": .bool,
                        "doDate": .optional(of: .string),
                        "deadline": .optional(of: .string)
                    ])
                ),
                description: "Data about all of the todos in the specified todo source, including their ID, source ID, title, description, completion status, do date, and deadline."
            ),
            displayTitle: "Get Todos",
            defaultProgressDescription: "Getting Todos...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let sourceID = parameters.inputs[0] as! String
                
                let sources = try! await todoProvider.getTodoSources()
                guard let source = sources.first(where: { $0.id == sourceID }) else {
                    return "Error: Todo source with specified ID not found."
                }
                
                let todos = try! await todoProvider.getTodos(for: source)
                
                return todos.map { todo in
                    return [
                        "id": todo.id,
                        "sourceID": todo.source.id,
                        "title": todo.title,
                        "description": todo.description,
                        "completed": todo.completed,
                        "doDate": todo.doDate?.dateString,
                        "deadline": todo.deadline?.dateString
                    ]
                }
            }
        )
    }
}

extension Date {
    var dateString: String {
        return getDateString(forDate: self)
    }
}
