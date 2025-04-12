//
//  NavigationBar.swift
//  Hackchat
//
//  Created by Liam Willey on 3/21/25.
//

import SwiftUI

enum NavigationAlignment {
    case leading
    case trailing
    case none
}

struct NavigationBar<Content: View>: View {
    @Environment(\.managedObjectContext) private var viewContext

    let title: String
    let items: () -> Content

    init(_ title: String, @ViewBuilder navItems: @escaping () -> Content) {
        self.title = title
        self.items = navItems
    }

    var body: some View {
        HStack(spacing: 13) {
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
    let alignment: NavigationAlignment
    let action: () -> Void
    
    init(_ icon: String, alignment: NavigationAlignment = .none, action: @escaping () -> Void) {
        self.icon = icon
        self.alignment = alignment
        self.action = action
    }
    
    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer()
            }
            Button {
                action()
            } label: {
                Image(systemName: icon)
                    .imageScale(.large)
                    .fontWeight(.medium)
            }
            .depressedButtonStyle()
            if alignment == .leading {
                Spacer()
            }
        }
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
