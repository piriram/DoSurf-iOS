import CoreData
import RxSwift

// MARK: - Repository Protocol
protocol NoteRepositoryProtocol {
    func saveSurfRecord(_ record: SurfRecordData) -> Single<Void>
    func fetchAllSurfRecords() -> Single<[SurfRecordData]>
    func fetchSurfRecords(for beachID: Int) -> Single<[SurfRecordData]>
    func fetchSurfRecord(by id: NSManagedObjectID) -> Single<SurfRecordData?>
    func deleteSurfRecord(by id: NSManagedObjectID) -> Single<Void>
    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void>
}



// MARK: - Repository Implementation
final class SurfRecordRepository: NoteRepositoryProtocol {
    private let coreDataStack: CoreDataManager
    
    init(coreDataStack: CoreDataManager = .shared) {
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
                    let beachKey = self.beachIDAttributeKeyIfExists(in: backgroundContext)
                    self.applyRecordValues(record, to: surfRecordMO, beachKey: beachKey)

                    // Create SurfChart entities
                    guard let chartEntity = NSEntityDescription.entity(forEntityName: "SurfChart", in: backgroundContext) else {
                        observer(.failure(RepositoryError.entityNotFound("SurfChart")))
                        return
                    }

                    let chartObjects = record.charts.map {
                        self.makeChartManagedObject(from: $0, chartEntity: chartEntity, in: backgroundContext)
                    }
                    
                    // Set relationship
                    surfRecordMO.setValue(NSSet(array: chartObjects), forKey: SurfRecordField.charts)
                    
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
                    let beachKey = self.beachIDAttributeKeyIfExists(in: backgroundContext)
                    self.applyRecordValues(record, to: managedObject, beachKey: beachKey)

                    // Update charts relationship (replace all)
                    if let existingCharts = managedObject.value(forKey: SurfRecordField.charts) as? NSSet {
                        existingCharts
                            .compactMap { $0 as? NSManagedObject }
                            .forEach { backgroundContext.delete($0) }
                    }

                    // Create new charts
                    guard let chartEntity = NSEntityDescription.entity(forEntityName: "SurfChart", in: backgroundContext) else {
                        observer(.failure(RepositoryError.entityNotFound("SurfChart")))
                        return
                    }

                    let chartObjects = record.charts.map {
                        self.makeChartManagedObject(from: $0, chartEntity: chartEntity, in: backgroundContext)
                    }
                    
                    managedObject.setValue(NSSet(array: chartObjects), forKey: SurfRecordField.charts)
                    
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
    
    private enum SurfRecordField {
        static let surfDate = "surfDate"
        static let startTime = "startTime"
        static let endTime = "endTime"
        static let rating = "rating"
        static let memo = "memo"
        static let isPin = "isPin"
        static let charts = "charts"

        static let time = "time"
        static let windSpeed = "windSpeed"
        static let windDirection = "windDirection"
        static let waveHeight = "waveHeight"
        static let wavePeriod = "wavePeriod"
        static let waveDirection = "waveDirection"
        static let airTemperature = "airTemperature"
        static let waterTemperature = "waterTemperature"
        static let weatherIconName = "weatherIconName"
    }

    private func applyRecordValues(_ record: SurfRecordData, to managedObject: NSManagedObject, beachKey: String?) {
        managedObject.setValue(record.surfDate, forKey: SurfRecordField.surfDate)
        managedObject.setValue(record.startTime, forKey: SurfRecordField.startTime)
        managedObject.setValue(record.endTime, forKey: SurfRecordField.endTime)
        managedObject.setValue(record.rating, forKey: SurfRecordField.rating)
        managedObject.setValue(record.memo, forKey: SurfRecordField.memo)
        managedObject.setValue(record.isPin, forKey: SurfRecordField.isPin)
        if let beachKey {
            managedObject.setValue(record.beachID, forKey: beachKey)
        }
    }

    private func makeChartManagedObject(
        from chartData: SurfChartData,
        chartEntity: NSEntityDescription,
        in context: NSManagedObjectContext
    ) -> NSManagedObject {
        let chartMO = NSManagedObject(entity: chartEntity, insertInto: context)
        chartMO.setValue(chartData.time, forKey: SurfRecordField.time)
        chartMO.setValue(chartData.windSpeed, forKey: SurfRecordField.windSpeed)
        chartMO.setValue(chartData.windDirection, forKey: SurfRecordField.windDirection)
        chartMO.setValue(chartData.waveHeight, forKey: SurfRecordField.waveHeight)
        chartMO.setValue(chartData.wavePeriod, forKey: SurfRecordField.wavePeriod)
        chartMO.setValue(chartData.waveDirection, forKey: SurfRecordField.waveDirection)
        chartMO.setValue(chartData.airTemperature, forKey: SurfRecordField.airTemperature)
        chartMO.setValue(chartData.waterTemperature, forKey: SurfRecordField.waterTemperature)
        chartMO.setValue(chartData.weatherIconName, forKey: SurfRecordField.weatherIconName)
        return chartMO
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
        guard let surfDate = managedObject.value(forKey: SurfRecordField.surfDate) as? Date,
              let startTime = managedObject.value(forKey: SurfRecordField.startTime) as? Date,
              let endTime = managedObject.value(forKey: SurfRecordField.endTime) as? Date else {
            return nil
        }
        
        let beachID: Int
        if let beachKey = beachIDAttributeKeyIfExists(for: managedObject) {
            beachID = (managedObject.value(forKey: beachKey) as? NSNumber)?.intValue ?? 0
        } else {
            beachID = 0
        }
        let rating = managedObject.value(forKey: SurfRecordField.rating) as? Int16 ?? 0
        let memo = managedObject.value(forKey: SurfRecordField.memo) as? String
        let isPin = managedObject.value(forKey: SurfRecordField.isPin) as? Bool ?? false

        var chartData: [SurfChartData] = []
        if let charts = managedObject.value(forKey: SurfRecordField.charts) as? NSSet {
            chartData = charts.compactMap { chartMO in
                guard let chartMO = chartMO as? NSManagedObject,
                      let time = chartMO.value(forKey: SurfRecordField.time) as? Date else { return nil }

                return SurfChartData(
                    time: time,
                    windSpeed: chartMO.value(forKey: SurfRecordField.windSpeed) as? Double ?? 0.0,
                    windDirection: chartMO.value(forKey: SurfRecordField.windDirection) as? Double ?? 0.0,
                    waveHeight: chartMO.value(forKey: SurfRecordField.waveHeight) as? Double ?? 0.0,
                    wavePeriod: chartMO.value(forKey: SurfRecordField.wavePeriod) as? Double ?? 0.0,
                    waveDirection: chartMO.value(forKey: SurfRecordField.waveDirection) as? Double ?? 0.0,
                    airTemperature: chartMO.value(forKey: SurfRecordField.airTemperature) as? Double ?? 0.0,
                    waterTemperature: chartMO.value(forKey: SurfRecordField.waterTemperature) as? Double ?? 0.0,
                    weatherIconName: chartMO.value(forKey: SurfRecordField.weatherIconName) as? String ?? ""
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
