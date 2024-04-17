import Foundation

func computeDateFromString(_ str: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Set locale to ensure correct parsing
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Optional: Set if you need the date in UTC

    let convertedDate = dateFormatter.date(from: str)
    return convertedDate
}
