import CoreData
import RxSwift

final class MockSurfRecordRepository: NoteRepositoryProtocol {
    private let inMemoryRepository: SurfRecordRepository

    init(coreDataManager: CoreDataManager = CoreDataManager(inMemory: true)) {
        self.inMemoryRepository = SurfRecordRepository(coreDataStack: coreDataManager)
    }

    func saveSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        inMemoryRepository.saveSurfRecord(record)
    }

    func fetchAllSurfRecords() -> Single<[SurfRecordData]> {
        inMemoryRepository.fetchAllSurfRecords()
    }

    func fetchSurfRecords(for beachID: Int) -> Single<[SurfRecordData]> {
        inMemoryRepository.fetchSurfRecords(for: beachID)
    }

    func fetchSurfRecord(byRecordId recordId: String) -> Single<SurfRecordData?> {
        inMemoryRepository.fetchSurfRecord(byRecordId: recordId)
    }

    func fetchSurfRecord(by id: NSManagedObjectID) -> Single<SurfRecordData?> {
        inMemoryRepository.fetchSurfRecord(by: id)
    }

    func deleteSurfRecord(by id: NSManagedObjectID) -> Single<Void> {
        inMemoryRepository.deleteSurfRecord(by: id)
    }

    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        inMemoryRepository.updateSurfRecord(record)
    }
}
