//
//  Date+Extensions.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//

import Foundation

// MARK: - Date Formatting
extension DateFormatter {
    static let beachDumpFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    static func make(format: String, locale: Locale = .current, calendar: Calendar = .current) -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = format
        df.locale = locale
        df.calendar = calendar
        return df
    }
}

extension Date {
    func asDumpString() -> String {
        DateFormatter.beachDumpFormatter.string(from: self)
    }
}

public extension Date {
    // Formatter for Korean month, day, and weekday (e.g., "9월 30일 화요일")
    private static let koreanMonthDayWeekdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일 EEEE"
        return df
    }()

    /// A formatted string in Korean locale like "9월 30일 화요일"
    var koreanMonthDayWeekday: String {
        return Date.koreanMonthDayWeekdayFormatter.string(from: self)
    }

    func formattedString(format: String, locale: Locale = .current, calendar: Calendar = .current) -> String {
        return DateFormatter.make(format: format, locale: locale, calendar: calendar).string(from: self)
    }
}
