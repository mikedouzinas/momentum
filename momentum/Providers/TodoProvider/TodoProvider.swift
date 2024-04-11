import Foundation
import CoreGraphics

struct TodoSource: Identifiable {
    let id: String
    let title: String
    let canAddTodos: Bool
    let canEditTodos: Bool
    let canDeleteTodos: Bool
    let canReadTodos: Bool
    let color: CGColor?
}

struct Todo: Identifiable {
    let id: String
    let source: TodoSource
    let title: String
    let description: String
    let completed: Bool
    let doDate: Date?
    let deadline: Date?
}

protocol TodoProvider {
    func getTodoSources() async throws -> [TodoSource]
    func getDefaultTodoSource() async throws -> TodoSource
    func getTodos(for source: TodoSource) async throws -> [Todo]
    func createTodo(for source: TodoSource) async throws -> Todo
    func updateTodo(todo: Todo) async throws -> Todo
    func deleteTodo(in source: TodoSource, id: String) async throws
}