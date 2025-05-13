import Foundation
import CoreData
import RxSwift

// MARK: - Use Cases Protocol
protocol SurfRecordUseCaseProtocol {
    func saveSurfRecord(
        surfDate: Date,
        startTime: Date,
        endTime: Date,
        beachID: Int,
        rating: Int16,
        memo: String?,
        isPin: Bool,
        charts: [Chart]
    ) -> Single<Void>
    
    func fetchAllSurfRecords() -> Single<[SurfRecordData]>
    func fetchSurfRecords(for beachID: Int) -> Single<[SurfRecordData]>
    func fetchSurfRecord(by id: NSManagedObjectID) -> Single<SurfRecordData?>
    func deleteSurfRecord(by id: NSManagedObjectID) -> Single<Void>
    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void>
}

// MARK: - Use Case Implementation
final class SurfRecordUseCase: SurfRecordUseCaseProtocol {
    private let repository: NoteRepositoryProtocol
    
    init(repository: NoteRepositoryProtocol = SurfRecordRepository()) {
        self.repository = repository
    }
    
    func saveSurfRecord(
        surfDate: Date,
        startTime: Date,
        endTime: Date,
        beachID: Int,
        rating: Int16,
        memo: String?,
        isPin: Bool,
        charts: [Chart]
    ) -> Single<Void> {
        let surfRecordData = SurfRecordData(
            beachID: beachID,
            id: nil,
            surfDate: surfDate,
            startTime: startTime,
            endTime: endTime,
            rating: rating,
            memo: memo,
            isPin: isPin,
            charts: charts.map { chart in
                SurfChartData(
                    time: chart.time,
                    windSpeed: chart.windSpeed,
                    windDirection: chart.windDirection,
                    waveHeight: chart.waveHeight,
                    wavePeriod: chart.wavePeriod,
                    waveDirection: chart.waveDirection,
                    airTemperature: chart.airTemperature,
                    waterTemperature: chart.waterTemperature,
                    weatherIconName: String(chart.weather.rawValue)
                )
            }
        )
        
        return repository.saveSurfRecord(surfRecordData)
    }
    
    func fetchAllSurfRecords() -> Single<[SurfRecordData]> {
        return repository.fetchAllSurfRecords()
    }
    
    func fetchSurfRecords(for beachID: Int) -> Single<[SurfRecordData]> {
        return repository.fetchSurfRecords(for: beachID)
    }
    
    func fetchSurfRecord(by id: NSManagedObjectID) -> Single<SurfRecordData?> {
        return repository.fetchSurfRecord(by: id)
    }
    
    func deleteSurfRecord(by id: NSManagedObjectID) -> Single<Void> {
        return repository.deleteSurfRecord(by: id)
    }
    
    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        return repository.updateSurfRecord(record)
    }
}
