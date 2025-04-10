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
                        newChat.name = "New Chat"
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
                            .contentShape(.contextMenuPreview, .rect(cornerRadius: 15))
                            .contextMenu {
                                Button(role: .destructive) {
                                    // TODO: add confirmation
                                    coreDataManager.persistentContainer.viewContext.delete(chat)
                                    coreDataManager.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                // If the app is quit and there is a response being generated in a chat, the said chat's `isResponding` property will be true. The state will be incorrect as any `URLSession`s are cancelled on termination
                if !hasPaused { // Check if we've already set the chat states the first time this view was rendered
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
