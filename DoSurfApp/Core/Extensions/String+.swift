//
//  String+.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

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
