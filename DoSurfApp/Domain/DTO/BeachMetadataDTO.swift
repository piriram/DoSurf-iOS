import Foundation

struct BeachMetadataDTO {
    let beachId: Int
    let region: String
    let beach: String
    let lastUpdated: Date
    let totalForecasts: Int
    let status: String
    let earliestForecast: Date?
    let latestForecast: Date?
    let nextForecastTime: Date?
    
    func toDomain() -> BeachMetadata {
        return BeachMetadata(
            id: String(beachId),
            name: beach,
            region: region,
            status: status,
            lastUpdated: lastUpdated,
            totalForecasts: totalForecasts
        )
    }
}
