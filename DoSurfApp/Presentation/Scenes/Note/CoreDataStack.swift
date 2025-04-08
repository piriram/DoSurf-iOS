import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }

    init(inMemory: Bool = false) {
        // Use merged model from all bundles so we don't depend on a specific container name
        guard let model = NSManagedObjectModel.mergedModel(from: [Bundle.main]) else {
            fatalError("⚠️ Failed to load Core Data model from bundle.")
        }
        // Name is arbitrary when providing an explicit model
        persistentContainer = NSPersistentContainer(name: "CoreDataStack", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production you may want to assert/log instead of fatalError
                fatalError("Unresolved Core Data error: \(error), userInfo: \(error.userInfo)")
            }
        }
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = persistentContainer.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }
}
