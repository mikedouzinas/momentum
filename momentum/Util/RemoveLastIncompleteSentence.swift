func removeLastIncompleteSentence(_ text: String, separators: [Character]) -> String {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let lastSeparatorIndex = trimmedText.lastIndex { char in
        separators.contains(char)
    }
    
    if let lastSeparatorIndex = lastSeparatorIndex {
        let lastSentenceEndIndex = trimmedText.index(after: lastSeparatorIndex)
        return String(trimmedText[..<lastSentenceEndIndex])
    } else {
        return ""
    }
}
