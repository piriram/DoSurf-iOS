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
}

extension Date {
    func asDumpString() -> String {
        DateFormatter.beachDumpFormatter.string(from: self)
    }
}
