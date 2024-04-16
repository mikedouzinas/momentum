indirect enum ActionDataType {
    case array(of: ActionDataType)
    case optional(of: ActionDataType)
    case int
    case double
    case bool
    case string
    case dict([String: ActionDataType])
    
    func describe() -> String {
        switch self {
        case .array(let innerType):
            return "[\(innerType.describe())]"
        case .optional(let innerType):
            return "\(innerType.describe())?"
        case .int:
            return "Int"
        case .double:
            return "Double"
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .dict(let keysAndValueTypes):
            return "Dict[\n" + keysAndValueTypes.map { "\($0): \($1.describe())" }.joined(separator: ",\n") + "\n]"
        }
    }
}
