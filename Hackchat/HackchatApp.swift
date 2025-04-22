//
//  HackchatApp.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

@main
struct HackchatApp: App {
    @ObservedObject private var coreDataManager = CoreDataManager.shared
    // We initalize the object here because NWPathMonitor has a bug where the connection state will always be disconnected
    @ObservedObject private var networkManager = NetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              coreDataManager.persistentContainer.viewContext)
        }
    }
}
