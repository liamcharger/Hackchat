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
    
    func chatNumber(_ chats: [Chat]) -> String {
        let chatNames = chats.compactMap(\.name)
        let chatNameCount = chatNames.filter({ $0.contains("Untitled") }).count // Only include the chats that start with "New Chat"
        
        if chatNameCount > 0 {
            var highestAvailableNum = 0
            for name in chatNames {
                if let last = name.split(separator: " ").last, let num = Int(last) {
                    // Set the highest available number to the greatest current chat number
                    highestAvailableNum = max(highestAvailableNum, num)
                } else {
                    // The chat name is "New Chat", handled in the last return
                }
            }
            // Return the number one higher than others previously used
            return " \(highestAvailableNum + 1)"
        }
        // No existing chats, we can create a chat called "New Chat"
        return ""
    }
    
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
