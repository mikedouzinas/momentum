import Foundation

func getDateString(forDate date: Date = .now) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    
    return dateFormatter.string(from: date)
}
