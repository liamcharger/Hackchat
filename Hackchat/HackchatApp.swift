//
//  HackchatApp.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

@main
struct HackchatApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              coreDataManager.persistentContainer.viewContext)
        }
    }
}
