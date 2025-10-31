//
//  RecordFilter.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation

// MARK: - RecordFilter
enum RecordFilter: Equatable {
    case all
    case pinned
    case datePreset(DatePreset)
    case dateRange(start: Date, end: Date)
    case rating(Int)
}
