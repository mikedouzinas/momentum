extension BuiltInActions {
    func getTodoSources(withTodoProvider todoProvider: TodoProvider) -> Action {
        return .init(
            identifier: "get_todo_sources",
            description: "Gets all of the user's todo sources.",
            inputs: [],
            output: .init(
                type: .array(
                    of: .dict([
                        "id": .string,
                        "title": .string,
                        "canAddTodos": .bool,
                        "canEditTodos": .bool,
                        "canDeleteTodos": .bool,
                        "canReadTodos": .bool,
                    ])
                ),
                description: "Data about all of the user's todo sources, including their ID, title, and access control information."
            ),
            displayTitle: "Get Todo Sources",
            defaultProgressDescription: "Getting Todo Sources...",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let result = try! await todoProvider.getTodoSources()
                
                return result.map { todoSource in
                    return [
                        "id": todoSource.id,
                        "title": todoSource.title,
                        "canAddTodos": todoSource.canAddTodos,
                        "canEditTodos": todoSource.canEditTodos,
                        "canDeleteTodos": todoSource.canDeleteTodos,
                        "canReadTodos": todoSource.canReadTodos,
                    ]
                }
            }
        )
    }
}
