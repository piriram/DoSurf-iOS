import Foundation

extension String {
    func toDate(dateFormat: String) -> Date?{
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = TimeZone.current
        return formatter.date(from: self)
    }
}
