import Foundation

func sleepUntil(_ date: Date) async throws {
    let now = Date()
    guard date > now else {
        // The date is in the past, no need to sleep
        return
    }
    
    let interval = date.timeIntervalSince(now)
    let nanoseconds = UInt64(interval * 1_000_000_000) // convert seconds to nanoseconds
    
    try await Task.sleep(nanoseconds: nanoseconds)
}
