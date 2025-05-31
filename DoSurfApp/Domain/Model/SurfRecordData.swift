import CoreData

// MARK: - Data Transfer Objects
struct SurfRecordData {
    let beachID: Int
    let id: NSManagedObjectID?
    let surfDate: Date
    let startTime: Date
    let endTime: Date
    let rating: Int16
    let memo: String?
    let isPin: Bool
    let charts: [SurfChartData]
}
