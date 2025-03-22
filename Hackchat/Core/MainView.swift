//
//  MainView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var coreDataManager = CoreDataManager.shared
    
    @FetchRequest(entity: Chat.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Chat.timestamp, ascending: true)]) var chats: FetchedResults<Chat>
    
    @State private var hasPaused = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavigationBar("Chats") {
                    Spacer()
                    NavigationBarButton("square.and.pencil") {
                        let newChat = Chat(context: viewContext)
                        newChat.name = "My Chat \(Int.random(in: 1...1000))"
                        newChat.id = UUID()
                        newChat.timestamp = Date()
                        newChat.messages = []
                        
                        coreDataManager.save()
                    }
                }
                Divider()
                ScrollView {
                    VStack {
                        ForEach(chats) { chat in
                            NavigationLink {
                                ChatView(chat: chat)
                            } label: {
                                ChatRowView(chat: chat)
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                if !hasPaused {
                    for chat in chats {
                        chat.isResponding = false
                    }
                    
                    self.hasPaused = true
                    self.coreDataManager.save()
                }
            }
        }
    }
}

struct ChatRowView: View {
    var chat: Chat
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chat.name ?? "Untitled")
                    .foregroundStyle(Color.primary)
                    .fontWeight(.bold)
                Text((chat.timestamp ?? Date()).formatted(.dateTime.day().month().year()))
                    .foregroundStyle(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

#Preview {
    MainView()
}
