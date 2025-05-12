//
//  ArchivedChatsView.swift
//  Hackchat
//
//  Created by Liam Willey on 4/22/25.
//

import SwiftUI

struct ArchivedChatsView: View {
    @ObservedObject private var mainViewModel = MainViewModel.shared
    
    @State private var showChatDeleteConfirmation = false
    @State private var selectedChat: Chat?
    
    @FetchRequest(entity: Chat.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Chat.lastEdited, ascending: false)]) var chats: FetchedResults<Chat>
    
    private var filteredChats: [Chat] {
        // TODO: add search functionality
        return self.chats.filter { _ in
            return true
        }
    }
    private var archivedChats: [Chat] {
        filteredChats.filter { $0.archived }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                NavigationBar("Archived Chats") {
                    NavigationBackButton()
                }
                if archivedChats.isEmpty {
                    InfoMessageView(title: "No archived chats", description: "When you archive a chat, it will show up here.")
                } else {
                    ChatListView(chats: archivedChats, geo: geo, archived: true) { chat in
                        Button {
                            playHaptic()
                            mainViewModel.unarchiveChat(chat)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        Button(role: .destructive) {
                            selectedChat = chat
                            showChatDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .confirmationDialog("Delete Chat", isPresented: $showChatDeleteConfirmation, actions: {
            Button(role: .destructive) {
                guard let selectedChat else { return }
                
                playHaptic()
                mainViewModel.deleteChat(selectedChat)
            } label: {
                Text("Delete")
            }
        }, message: {
            Text("Are you sure you want to delete \"\(selectedChat?.name ?? "this chat")\"?")
        })
    }
}

#Preview {
    ArchivedChatsView()
}
