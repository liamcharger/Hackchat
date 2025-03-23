//
//  NavigationBar.swift
//  Hackchat
//
//  Created by Liam Willey on 3/21/25.
//

import SwiftUI

struct NavigationBar<Content: View>: View {
    @Environment(\.managedObjectContext) private var viewContext

    let title: String
    let items: () -> Content

    init(_ title: String, @ViewBuilder navItems: @escaping () -> Content) {
        self.title = title
        self.items = navItems
    }

    var body: some View {
        HStack {
            items()
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.primary)
        .padding(12)
        .overlay {
            Text(title)
                .fontWeight(.semibold)
        }
    }
}

struct NavigationBarButton: View {
    let icon: String
    let action: () -> Void
    
    init(_ icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
                .imageScale(.large)
                .fontWeight(.medium)
        }
        .depressedButtonStyle()
    }
}

#Preview {
    NavigationBar("Chats") {
        NavigationBarButton("info.circle") {
            let newChat = Chat(context: CoreDataManager.shared.persistentContainer.viewContext)
            newChat.name = "My Chat \(Int.random(in: 1...1000))"
            newChat.id = UUID()
            newChat.timestamp = Date()
            newChat.messages = []
            
            CoreDataManager.shared.save()
        }
        Spacer()
        NavigationBarButton("square.and.pencil") {
            let newChat = Chat(context: CoreDataManager.shared.persistentContainer.viewContext)
            newChat.name = "My Chat \(Int.random(in: 1...1000))"
            newChat.id = UUID()
            newChat.timestamp = Date()
            newChat.messages = []
            
            CoreDataManager.shared.save()
        }
    }
}
