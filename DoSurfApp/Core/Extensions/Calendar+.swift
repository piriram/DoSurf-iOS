//
//  Calendar+.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//
import Foundation

public extension Calendar {
    /// date(연/월/일)와 time(시/분/초)을 합쳐 하나의 Date를 생성
    func combine(_ date: Date, withTimeOf time: Date) -> Date {
        let d = dateComponents([.year, .month, .day], from: date)
        let t = dateComponents([.hour, .minute, .second], from: time)
        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute
        comps.second = t.second
        return self.date(from: comps) ?? date
    }
}

