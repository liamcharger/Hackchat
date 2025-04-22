//
//  MainViewModel.swift
//  Hackchat
//
//  Created by Liam Willey on 4/21/25.
//

import CoreData

class MainViewModel: ObservableObject {
    static let shared = MainViewModel()
    
    private let coreDataManager = CoreDataManager.shared
    private var viewContext: NSManagedObjectContext {
        return coreDataManager.persistentContainer.viewContext
    }
    
    @Published var navigationPath = [Chat]()
    
    func deleteChat(_ chat: Chat) {
        viewContext.delete(chat)
        coreDataManager.save()
        
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func archiveChat(_ chat: Chat) {
        chat.archived = true
        coreDataManager.save()
    }
    
    func unarchiveChat(_ chat: Chat) {
        chat.archived = false
        coreDataManager.save()
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}
