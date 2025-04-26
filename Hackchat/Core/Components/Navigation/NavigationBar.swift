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
    let title: String
    let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        HStack(spacing: 18) {
            content()
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
