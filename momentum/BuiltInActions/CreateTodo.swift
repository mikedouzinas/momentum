import Foundation

extension BuiltInActions {
    func createTodo(withTodoProvider todoProvider: TodoProvider) -> Action {
        return .init(
            identifier: "create_todo",
            description: "Creates a new todo in a specific todo source.",
            inputs: [
                .init(type: .string, displayTitle: "Source ID", identifier: "sourceID", description: "The ID of the todo source to create the todo in."),
                .init(type: .string, displayTitle: "Title", identifier: "title", description: "The title of the todo."),
                .init(type: .string, displayTitle: "Description", identifier: "description", description: "The description of the todo."),
                .init(type: .optional(of: .string), displayTitle: "Do Date", identifier: "doDate", description: "The date when the todo should be done, formatted as yyyy-MM-dd'T'HH:mm:ss (e.g. 2024-05-09T9:41:00)."),
                .init(type: .optional(of: .string), displayTitle: "Deadline", identifier: "deadline", description: "The deadline date for the todo, formatted as yyyy-MM-dd'T'HH:mm:ss (e.g. 2024-05-09T9:41:00).")
            ],
            output: .init(
                type: .string,
                description: "The ID of the newly created todo if the todo has been successfully created, and an error string otherwise."
            ),
            displayTitle: "Create Todo",
            defaultProgressDescription: "Creating Todo...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let sourceID = parameters.inputs[0] as! String
                let title = parameters.inputs[1] as! String
                let description = parameters.inputs[2] as! String
                let doDateString = parameters.inputs[3] as? String
                let deadlineString = parameters.inputs[4] as? String
                
                let sources = try! await todoProvider.getTodoSources()
                guard let source = sources.first(where: { $0.id == sourceID }) else {
                    return "Error: Todo source with specified ID not found."
                }
                
                let doDate = doDateString.flatMap { computeDateFromString($0) }
                let deadline = deadlineString.flatMap { computeDateFromString($0) }
                
                guard doDate == nil || doDate! >= Date() else {
                    return "Error: Do date must be in the future."
                }
                
                guard deadline == nil || deadline! >= Date() else {
                    return "Error: Deadline must be in the future."
                }
                
                let id = UUID().uuidString
                let todo = Todo(id: id, source: source, title: title, description: description, completed: false, doDate: doDate, deadline: deadline)
                
                let createdTodo = try! await todoProvider.createTodo(for: source, todo: todo)
                
                return "Success: \(createdTodo.id)"
            }
        )
    }
}
