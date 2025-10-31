import Foundation
import CoreData
import RxSwift

// MARK: - Repository Protocol
protocol SurfRecordRepositoryProtocol {
    func saveSurfRecord(_ record: SurfRecordData) -> Single<Void>
    func fetchAllSurfRecords() -> Single<[SurfRecordData]>
    func fetchSurfRecords(for beachID: Int) -> Single<[SurfRecordData]>
    func fetchSurfRecord(by id: NSManagedObjectID) -> Single<SurfRecordData?>
    func deleteSurfRecord(by id: NSManagedObjectID) -> Single<Void>
    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void>
}








