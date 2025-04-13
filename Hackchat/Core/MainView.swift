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
    
    @FetchRequest(entity: Chat.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Chat.lastEdited, ascending: false)]) var chats: FetchedResults<Chat>
    
    @State private var hasPaused = false
    @State private var isSearching = false
    @State private var showChatDeleteConfirmation = false
    @State private var searchText = ""
    // When deleting a chat via the confirmation dialog, the wrong chat object is captured. Deleting from a state fixes this
    @State private var selectedChat: Chat?
    @State private var path: [Chat] = []
    
    @FocusState private var isSearchFocused: Bool
    
    private let animation: Animation = .smooth(duration: 0.3)
    private var filteredChats: [Chat] {
        self.chats
            .filter {
                let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
                if !query.isEmpty {
                    guard let name = $0.name?.lowercased() else { return false }
                    return name.contains(query)
                }
                return true
            }
    }
    
    private func groupedChats(_ chats: [Chat]) -> [ChatDateGroup: [Chat]] {
        Dictionary(grouping: chats) { chat in
            ChatDateGroup.group(for: chat.lastEdited ?? (chat.timestamp ?? Date()))
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                NavigationBar("Chats") {
                    NavigationBarButton(isSearching ? "xmark" : "magnifyingglass", alignment: .leading) {
                        isSearching.toggle()
                        isSearchFocused = isSearching
                    }
                    .opacity((filteredChats.isEmpty && !isSearching) ? 0 : 1)
                    .animation(animation, value: filteredChats.isEmpty)
                    NavigationBarButton("square.and.pencil", alignment: .trailing) {
                        let newChat = Chat(context: viewContext)
                        let newChatLabel = "New Chat"
                        let chats = chats.filter({ ($0.name ?? "").contains(newChatLabel) })
                        
                        if !chats.isEmpty {
                            newChat.name = newChatLabel + " \(chats.count + 1)"
                        } else {
                            newChat.name = newChatLabel
                        }
                        newChat.id = UUID()
                        newChat.timestamp = Date()
                        newChat.messages = []
                        
                        coreDataManager.save()
                        
                        path.append(newChat)
                    }
                }
                if isSearching {
                    HStack(spacing: 7) {
                        Image(systemName: "magnifyingglass")
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        TextField("Search", text: $searchText)
                            .focused($isSearchFocused)
                            .submitLabel(searchText.trimmingCharacters(in: .whitespaces).isEmpty ? .return : .search)
                    }
                    .padding(10)
                    .background(Material.thin)
                    .clipShape(Capsule())
                    .onTapGesture {
                        isSearchFocused = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                Divider()
                if filteredChats.isEmpty {
                    InfoMessageView(title: "No chats found", description: "Start a new chat by tapping the pencil button in the top right corner.")
                } else {
                    ScrollView {
                        VStack {
                            ForEach(ChatDateGroup.allCases, id: \.self) { group in
                                if let chats = groupedChats(filteredChats)[group] {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(group.rawValue)
                                            .font(.system(size: 16))
                                            .foregroundStyle(.gray)
                                        ForEach(chats, id: \.id) { chat in
                                            NavigationLink(value: chat) {
                                                ChatRowView(chat: chat)
                                                    .transition(.opacity)
                                            }
                                            .contentShape(.contextMenuPreview, .rect(cornerRadius: 15))
                                            .contextMenu {
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
                            }
                        }
                        .navigationDestination(for: Chat.self) { chat in
                            ChatView(chat: chat)
                        }
                        .padding()
                    }
                }
            }
            .compositingGroup()
            .animation(animation, value: isSearching)
            .transition(.push(from: .top))
            .confirmationDialog("Delete Chat", isPresented: $showChatDeleteConfirmation, actions: {
                Button(role: .destructive) {
                    guard let selectedChat else { return }
                    
                    coreDataManager.persistentContainer.viewContext.delete(selectedChat)
                    coreDataManager.save()
                } label: {
                    Text("Delete")
                }
            }, message: {
                Text("Are you sure you want to delete \"\(selectedChat?.name ?? "this chat")\"?")
            })
            .onAppear {
                for chat in chats {
                    // Check lastEdited because we don't want to delete the chat if the user edited the custom instructions or title
                    if chat.messages.array().isEmpty && chat.lastEdited == nil {
                        // This deletes the chat when the user creates it and then doesn't use it
                        viewContext.delete(chat)
                        coreDataManager.save()
                    }
                }
                
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
    @ObservedObject var chatViewModel: ChatViewModel
    
    init(chat: Chat) {
        self.chatViewModel = ChatViewModel(chat)
    }
    
    var body: some View {
        HStack {
            Text(chatViewModel.chat.name ?? "Untitled")
                .foregroundStyle(Color.primary)
                .fontWeight(.semibold)
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
