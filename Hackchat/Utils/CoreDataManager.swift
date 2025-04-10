//
//  CoreDataManager.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "Hackchat")
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { storeDescription, error in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    private init() { }
}

extension CoreDataManager {
    func save() {
        guard persistentContainer.viewContext.hasChanges else { return }
        
        persistentContainer.viewContext.perform {
            do {
                try self.persistentContainer.viewContext.save()
            } catch {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to save view context: \(error.localizedDescription)")
            }
        }
    }
}
