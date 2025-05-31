import Foundation

// MARK: - RecordFilter
enum RecordFilter: Equatable {
    case all
    case pinned
    case datePreset(DatePreset)
    case dateRange(start: Date, end: Date)
    case rating(Int)
}
