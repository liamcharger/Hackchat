//
//  ChatListView.swift
//  Hackchat
//
//  Created by Liam Willey on 4/21/25.
//

import SwiftUI

struct ChatListView<V: View>: View {
    let chats: [Chat]
    let geo: GeometryProxy
    let archived: Bool
    let content: (Chat) -> V
    
    @State private var selectedChat: Chat?
    
    private func groupedChats(_ chats: [Chat]) -> [ChatDateGroup: [Chat]] {
        Dictionary(grouping: chats) { chat in
            ChatDateGroup.group(for: chat.lastEdited ?? (chat.timestamp ?? Date()))
        }
    }
    
    init(chats: [Chat], geo: GeometryProxy, archived: Bool = false, @ViewBuilder content: @escaping(Chat) -> V) {
        self.chats = chats
        self.geo = geo
        self.archived = archived
        
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                ForEach(ChatDateGroup.allCases, id: \.self) { group in
                    if let chats = groupedChats(chats)[group] {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(group.rawValue)
                                .font(.system(size: 16))
                                .foregroundStyle(.gray)
                            ForEach(chats, id: \.id) { chat in
                                // We use a sheet for the archived chats
                                Group {
                                    if archived {
                                        Button {
                                            selectedChat = chat
                                        } label: {
                                            ChatRowView(chat.name ?? "Untitled", showChevron: false)
                                        }
                                    } else {
                                        // This is at the root of the app, it's safe to use NavigationLink here
                                        NavigationLink(value: chat) {
                                            ChatRowView(chat.name ?? "Untitled")
                                        }
                                    }
                                }
                                .foregroundStyle(Color.primary)
                                .contentShape(.contextMenuPreview, .rect(cornerRadius: 15))
                                .contextMenu {
                                    content(chat)
                                } preview: {
                                    ChatView(chat, preview: true)
                                        .frame(width: geo.size.width / 1.1, height: geo.size.height / 1.5)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .compositingGroup()
            .transition(.opacity)
        }
        .sheet(item: $selectedChat) { chat in
            ChatView(chat, isArchived: true)
        }
    }
}
