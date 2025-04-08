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

struct SurfChartData {
    let time: Date
    let windSpeed: Double
    let windDirection: Double
    let waveHeight: Double
    let wavePeriod: Double
    let waveDirection: Double
    let airTemperature: Double
    let waterTemperature: Double
    let weatherIconName: String
}

// MARK: - Repository Implementation
final class SurfRecordRepository: SurfRecordRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    func saveSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(RepositoryError.unknown))
                return Disposables.create()
            }
            
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                do {
                    // Create SurfRecord entity
                    guard let surfRecordEntity = NSEntityDescription.entity(forEntityName: "SurfRecord", in: backgroundContext) else {
                        observer(.failure(RepositoryError.entityNotFound("SurfRecord")))
                        return
                    }
                    
                    let surfRecordMO = NSManagedObject(entity: surfRecordEntity, insertInto: backgroundContext)
                    surfRecordMO.setValue(record.surfDate, forKey: "surfDate")
                    surfRecordMO.setValue(record.startTime, forKey: "startTime")
                    surfRecordMO.setValue(record.endTime, forKey: "endTime")
                    surfRecordMO.setValue(record.rating, forKey: "rating")
                    surfRecordMO.setValue(record.memo, forKey: "memo")
                    surfRecordMO.setValue(record.isPin, forKey: "isPin")
                    if let beachKey = self.beachIDAttributeKeyIfExists(in: backgroundContext) {
                        surfRecordMO.setValue(record.beachID, forKey: beachKey)
                    }
                    
                    // Create SurfChart entities
                    guard let chartEntity = NSEntityDescription.entity(forEntityName: "SurfChart", in: backgroundContext) else {
                        observer(.failure(RepositoryError.entityNotFound("SurfChart")))
                        return
                    }
                    
                    let chartObjects = record.charts.map { chartData -> NSManagedObject in
                        let chartMO = NSManagedObject(entity: chartEntity, insertInto: backgroundContext)
                        chartMO.setValue(chartData.time, forKey: "time")
                        chartMO.setValue(chartData.windSpeed, forKey: "windSpeed")
                        chartMO.setValue(chartData.windDirection, forKey: "windDirection")
                        chartMO.setValue(chartData.waveHeight, forKey: "waveHeight")
                        chartMO.setValue(chartData.wavePeriod, forKey: "wavePeriod")
                        chartMO.setValue(chartData.waveDirection, forKey: "waveDirection")
                        chartMO.setValue(chartData.airTemperature, forKey: "airTemperature")
                        chartMO.setValue(chartData.waterTemperature, forKey: "waterTemperature")
                        chartMO.setValue(chartData.weatherIconName, forKey: "weatherIconName")
                        return chartMO
                    }
                    
                    // Set relationship
                    surfRecordMO.setValue(NSSet(array: chartObjects), forKey: "charts")
                    
                    // Save context
                    try backgroundContext.save()
                    
                    DispatchQueue.main.async {
                        observer(.success(()))
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.failure(RepositoryError.saveError(error)))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchAllSurfRecords() -> Single<[SurfRecordData]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(RepositoryError.unknown))
                return Disposables.create()
            }
            
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "SurfRecord")
                    request.sortDescriptors = [NSSortDescriptor(key: "surfDate", ascending: false)]
                    
                    let results = try backgroundContext.fetch(request)
                    let surfRecords = results.compactMap { self.mapToSurfRecordData($0) }
                    
                    DispatchQueue.main.async {
                        observer(.success(surfRecords))
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.failure(RepositoryError.fetchError(error)))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchSurfRecords(for beachID: Int) -> Single<[SurfRecordData]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(RepositoryError.unknown))
                return Disposables.create()
            }
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "SurfRecord")
                    if let beachKey = self.beachIDAttributeKeyIfExists(in: backgroundContext) {
                        request.predicate = NSPredicate(format: "%K == %d", beachKey, beachID)
                    } else {
                        // If the attribute doesn't exist, fetch all records instead of crashing
                        request.predicate = nil
                    }
                    request.sortDescriptors = [NSSortDescriptor(key: "surfDate", ascending: false)]
                    let results = try backgroundContext.fetch(request)
                    let surfRecords = results.compactMap { self.mapToSurfRecordData($0) }
                    DispatchQueue.main.async {
                        observer(.success(surfRecords))
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.failure(RepositoryError.fetchError(error)))
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchSurfRecord(by id: NSManagedObjectID) -> Single<SurfRecordData?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(RepositoryError.unknown))
                return Disposables.create()
            }
            
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                do {
                    let managedObject = try backgroundContext.existingObject(with: id)
                    let surfRecord = self.mapToSurfRecordData(managedObject)
                    
                    DispatchQueue.main.async {
                        observer(.success(surfRecord))
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.failure(RepositoryError.fetchError(error)))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func deleteSurfRecord(by id: NSManagedObjectID) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(RepositoryError.unknown))
                return Disposables.create()
            }
            
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                do {
                    let managedObject = try backgroundContext.existingObject(with: id)
                    backgroundContext.delete(managedObject)
                    try backgroundContext.save()
                    
                    DispatchQueue.main.async {
                        observer(.success(()))
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.failure(RepositoryError.deleteError(error)))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self,
                  let objectID = record.id else {
                observer(.failure(RepositoryError.invalidObjectID))
                return Disposables.create()
            }
            
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                do {
                    let managedObject = try backgroundContext.existingObject(with: objectID)
                    
                    // Update properties
                    managedObject.setValue(record.surfDate, forKey: "surfDate")
                    managedObject.setValue(record.startTime, forKey: "startTime")
                    managedObject.setValue(record.endTime, forKey: "endTime")
                    managedObject.setValue(record.rating, forKey: "rating")
                    managedObject.setValue(record.memo, forKey: "memo")
                    managedObject.setValue(record.isPin, forKey: "isPin")
                    if let beachKey = self.beachIDAttributeKeyIfExists(in: backgroundContext) {
                        managedObject.setValue(record.beachID, forKey: beachKey)
                    }
                    
                    // Update charts relationship (simplified - in real app you might want to handle this more carefully)
                    if let existingCharts = managedObject.value(forKey: "charts") as? NSSet {
                        existingCharts.forEach { backgroundContext.delete($0 as! NSManagedObject) }
                    }
                    
                    // Create new charts
                    guard let chartEntity = NSEntityDescription.entity(forEntityName: "SurfChart", in: backgroundContext) else {
                        observer(.failure(RepositoryError.entityNotFound("SurfChart")))
                        return
                    }
                    
                    let chartObjects = record.charts.map { chartData -> NSManagedObject in
                        let chartMO = NSManagedObject(entity: chartEntity, insertInto: backgroundContext)
                        chartMO.setValue(chartData.time, forKey: "time")
                        chartMO.setValue(chartData.windSpeed, forKey: "windSpeed")
                        chartMO.setValue(chartData.windDirection, forKey: "windDirection")
                        chartMO.setValue(chartData.waveHeight, forKey: "waveHeight")
                        chartMO.setValue(chartData.wavePeriod, forKey: "wavePeriod")
                        chartMO.setValue(chartData.waveDirection, forKey: "waveDirection")
                        chartMO.setValue(chartData.airTemperature, forKey: "airTemperature")
                        chartMO.setValue(chartData.waterTemperature, forKey: "waterTemperature")
                        chartMO.setValue(chartData.weatherIconName, forKey: "weatherIconName")
                        return chartMO
                    }
                    
                    managedObject.setValue(NSSet(array: chartObjects), forKey: "charts")
                    
                    try backgroundContext.save()
                    
                    DispatchQueue.main.async {
                        observer(.success(()))
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.failure(RepositoryError.updateError(error)))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Attribute Key Helpers
    private func beachIDAttributeKeyIfExists(in context: NSManagedObjectContext) -> String? {
        if let entity = NSEntityDescription.entity(forEntityName: "SurfRecord", in: context) {
            let attrs = entity.attributesByName
            if attrs["beachId"] != nil { return "beachId" }
            if attrs["beachID"] != nil { return "beachID" }
        }
        return nil
    }
    private func beachIDAttributeKeyIfExists(for object: NSManagedObject) -> String? {
        let attrs = object.entity.attributesByName
        if attrs["beachId"] != nil { return "beachId" }
        if attrs["beachID"] != nil { return "beachID" }
        return nil
    }
    
    // MARK: - Private Helpers
    private func mapToSurfRecordData(_ managedObject: NSManagedObject) -> SurfRecordData? {
        guard let surfDate = managedObject.value(forKey: "surfDate") as? Date,
              let startTime = managedObject.value(forKey: "startTime") as? Date,
              let endTime = managedObject.value(forKey: "endTime") as? Date else {
            return nil
        }
        
        let beachID: Int
        if let beachKey = beachIDAttributeKeyIfExists(for: managedObject) {
            beachID = (managedObject.value(forKey: beachKey) as? NSNumber)?.intValue ?? 0
        } else {
            beachID = 0
        }
        let rating = managedObject.value(forKey: "rating") as? Int16 ?? 0
        let memo = managedObject.value(forKey: "memo") as? String
        let isPin = managedObject.value(forKey: "isPin") as? Bool ?? false
        
        var chartData: [SurfChartData] = []
        if let charts = managedObject.value(forKey: "charts") as? NSSet {
            chartData = charts.compactMap { chartMO in
                guard let chartMO = chartMO as? NSManagedObject,
                      let time = chartMO.value(forKey: "time") as? Date else { return nil }
                
                return SurfChartData(
                    time: time,
                    windSpeed: chartMO.value(forKey: "windSpeed") as? Double ?? 0.0,
                    windDirection: chartMO.value(forKey: "windDirection") as? Double ?? 0.0,
                    waveHeight: chartMO.value(forKey: "waveHeight") as? Double ?? 0.0,
                    wavePeriod: chartMO.value(forKey: "wavePeriod") as? Double ?? 0.0,
                    waveDirection: chartMO.value(forKey: "waveDirection") as? Double ?? 0.0,
                    airTemperature: chartMO.value(forKey: "airTemperature") as? Double ?? 0.0,
                    waterTemperature: chartMO.value(forKey: "waterTemperature") as? Double ?? 0.0,
                    weatherIconName: chartMO.value(forKey: "weatherIconName") as? String ?? ""
                )
            }.sorted { $0.time < $1.time }
        }
        
        return SurfRecordData(
            beachID: beachID,
            id: managedObject.objectID,
            surfDate: surfDate,
            startTime: startTime,
            endTime: endTime,
            rating: rating,
            memo: memo,
            isPin: isPin,
            charts: chartData
        )
    }
}

// MARK: - Repository Errors
enum RepositoryError: Error {
    case unknown
    case entityNotFound(String)
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case updateError(Error)
    case invalidObjectID
    
    var localizedDescription: String {
        switch self {
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .entityNotFound(let entityName):
            return "\(entityName) 엔티티를 찾을 수 없습니다."
        case .saveError(let error):
            return "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .fetchError(let error):
            return "데이터를 가져오는 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .deleteError(let error):
            return "삭제 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .updateError(let error):
            return "업데이트 중 오류가 발생했습니다: \(error.localizedDescription)"
        case .invalidObjectID:
            return "유효하지 않은 객체 ID입니다."
        }
    }
}
