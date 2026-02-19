import CoreData

// MARK: - Data Transfer Objects
struct SurfRecordData {
    let beachID: Int
    let id: NSManagedObjectID?
    let recordId: String
    let payloadVersion: Int16
    let lastModifiedAt: Date
    let deviceId: String
    let isDeleted: Bool
    let surfDate: Date
    let startTime: Date
    let endTime: Date
    let rating: Int16
    let memo: String?
    let isPin: Bool
    let charts: [SurfChartData]
    
    init(
        beachID: Int,
        id: NSManagedObjectID? = nil,
        recordId: String = UUID().uuidString,
        payloadVersion: Int16 = 1,
        lastModifiedAt: Date = Date(),
        deviceId: String = "ios-device",
        isDeleted: Bool = false,
        surfDate: Date,
        startTime: Date,
        endTime: Date,
        rating: Int16 = 0,
        memo: String? = nil,
        isPin: Bool = false,
        charts: [SurfChartData] = []
    ) {
        self.beachID = beachID
        self.id = id
        self.recordId = recordId
        self.payloadVersion = payloadVersion
        self.lastModifiedAt = lastModifiedAt
        self.deviceId = deviceId
        self.isDeleted = isDeleted
        self.surfDate = surfDate
        self.startTime = startTime
        self.endTime = endTime
        self.rating = rating
        self.memo = memo
        self.isPin = isPin
        self.charts = charts
    }
}
