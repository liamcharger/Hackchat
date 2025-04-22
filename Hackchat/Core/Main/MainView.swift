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
    @ObservedObject var mainViewModel = MainViewModel.shared
    
    @FetchRequest(entity: Chat.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Chat.lastEdited, ascending: false)]) var chats: FetchedResults<Chat>
    
    @State private var hasLoadedInitially = false
    @State private var isSearching = false
    @State private var showChatDeleteConfirmation = false
    @State private var showChatArchiveConfirmation = false
    @State private var searchText = ""
    // When deleting a chat via the confirmation dialog, the wrong chat object is captured. Deleting from a state fixes this
    @State private var selectedChat: Chat?
    
    @FocusState private var isSearchFocused: Bool
    
    private let animation: Animation = .smooth(duration: 0.3)
    
    private func filteredChats(archived: Bool = false) -> [Chat] {
        self.chats
            .filter {
                let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
                if !query.isEmpty {
                    guard let name = $0.name?.lowercased() else { return false }
                    let doesMatch = name.contains(query)
                    // When returning archived chats: include the current chat if it matches the query and is archived. Otherwise, return the chat if it's not archived and matches the query
                    return archived ? doesMatch && $0.archived : doesMatch
                }
                // There isn't a search, so just return the full list of chats, filtered accordingly
                return archived ? $0.archived : !$0.archived
            }
    }
    private func chatNumber() -> String {
        let chatNames = chats.compactMap(\.name)
        let chatNameCount = chatNames.filter({ $0.contains("New Chat") }).count // Only include the chats that start with "New Chat"
        
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
    private func deleteEmptyChats() {
        for chat in chats {
            // Check lastEdited because we don't want to delete the chat if the user edited the custom instructions/title, or typed a draft
            if chat.messages.array().isEmpty && chat.lastEdited == nil && chat.draft == nil {
                // This deletes the chat when the user creates it and then doesn't use it
                viewContext.delete(chat)
                coreDataManager.save()
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $mainViewModel.navigationPath) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    NavigationBar("My Chats") {
                        NavigationBarButton(isSearching ? "xmark" : "magnifyingglass", alignment: .leading) {
                            isSearching.toggle()
                            isSearchFocused = isSearching
                        }
                        .opacity((filteredChats().isEmpty && !isSearching) ? 0 : 1)
                        .animation(animation, value: filteredChats().isEmpty)
                        NavigationBarButton("square.and.pencil", alignment: .trailing) {
                            let newChat = Chat(context: viewContext)
                            newChat.name = "New Chat\(chatNumber())"
                            newChat.id = UUID()
                            newChat.timestamp = Date()
                            newChat.messages = []
                            
                            coreDataManager.save()
                            
                            mainViewModel.navigationPath.append(newChat)
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
                    if filteredChats().isEmpty {
                        InfoMessageView(title: "No chats found", description: "Start a new chat by tapping the pencil button in the top right corner.")
                    } else {
                        ScrollView {
                            ChatListView(chats: filteredChats(), geo: geo) { chat in
                                Button {
                                    selectedChat = chat
                                    showChatArchiveConfirmation = true
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                Button(role: .destructive) {
                                    selectedChat = chat
                                    showChatDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .navigationDestination(for: Chat.self) { chat in
                            ChatView(chat)
                        }
                    }
                    if !filteredChats(archived: true).isEmpty {
                        Divider()
                        NavigationLink {
                            VStack {
                                if filteredChats(archived: true).isEmpty {
                                    InfoMessageView(title: "No archived chats", description: "When you archive a chat, it will show up here.")
                                } else {
                                    ChatListView(chats: filteredChats(archived: true), geo: geo, archived: true) { chat in
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
                            .navigationTitle("Archived Chats")
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "archivebox")
                                Text("Archived Chats")
                            }
                            .foregroundStyle(Color.primary)
                        }
                        .padding(12)
                    }
                }
            }
            .compositingGroup()
            .animation(animation, value: isSearching)
            .transition(.push(from: .top))
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
            .confirmationDialog("Archive Chat", isPresented: $showChatArchiveConfirmation, actions: {
                Button {
                    guard let selectedChat else { return }
                    
                    playHaptic()
                    mainViewModel.archiveChat(selectedChat)
                } label: {
                    Text("Archive")
                }
            }, message: {
                Text("Are you sure you want to archive \"\(selectedChat?.name ?? "this chat")\"? It can be unarchived by tapping Archived Chats at the bottom of the screen.")
            })
            .onAppear {
                // If the app is quit and there is a response being generated in a chat, the said chat's `isResponding` property will be true. The state will be incorrect as any `URLSession`s are cancelled on termination
                if !hasLoadedInitially { // Check if we've already set the chat states the first time this view was rendered
                    for chat in chats {
                        chat.isResponding = false
                    }
                    coreDataManager.save()
                    
                    // Always have the view load with a blank chat
                    let chat = Chat(context: viewContext)
                    chat.id = UUID()
                    chat.name = "New Chat\(chatNumber())"
                    chat.timestamp = Date()
                    mainViewModel.navigationPath.append(chat)
                    
                    self.hasLoadedInitially = true
                }
                
                deleteEmptyChats()
            }
            .onChange(of: mainViewModel.navigationPath) { _, path in
                deleteEmptyChats()
            }
        }
    }
}

#Preview {
    MainView()
}
