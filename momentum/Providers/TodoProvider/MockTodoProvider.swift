import Foundation
import CoreGraphics

class MockTodoProvider: TodoProvider {
    var todoSources = MockTodoProvider.getMockTodoSources()
    var todos = MockTodoProvider.getMockTodos()
    
    func getTodoSources() async throws -> [TodoSource] {
        return todoSources
    }
    
    func getDefaultTodoSource() async throws -> TodoSource {
        return todoSources[0]
    }
    
    func getTodos(for source: TodoSource) async throws -> [Todo] {
        return todos.filter { $0.source.id == source.id }
    }
    
    func createTodo(for source: TodoSource, todo: Todo) async throws -> Todo {
        todos.append(todo)
        return todo
    }
    
    func updateTodo(todo: Todo) async throws -> Todo {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
            throw NSError(domain: "TodoNotFound", code: 404, userInfo: nil)
        }
        todos[index] = todo
        return todos[index]
    }
    
    func deleteTodo(in source: TodoSource, id: String) async throws {
        guard let index = todos.firstIndex(where: { $0.id == id && $0.source.id == source.id }) else {
            throw NSError(domain: "TodoNotFound", code: 404, userInfo: nil)
        }
        todos.remove(at: index)
    }
}

extension MockTodoProvider {
    static func getMockTodoSources() -> [TodoSource] {
        return [
            .init(id: "1", title: "Work", canAddTodos: true, canEditTodos: true, canDeleteTodos: false, canReadTodos: true, color: CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)),
            .init(id: "2", title: "Personal", canAddTodos: true, canEditTodos: true, canDeleteTodos: true, canReadTodos: true, color: CGColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1.0))
        ]
    }

    static func getMockTodos() -> [Todo] {
        let todoSources = getMockTodoSources()
        let currentDate = Date()
        return [
            .init(id: "T1", source: todoSources[0], title: "Complete Report", description: "Complete the monthly financial report", completed: false, doDate: currentDate, deadline: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)),
            .init(id: "T2", source: todoSources[1], title: "Doctor Appointment", description: "Annual health checkup", completed: false, doDate: currentDate, deadline: Calendar.current.date(byAdding: .day, value: 3, to: currentDate))
        ]
    }
}
