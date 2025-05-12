//
//  ChatRowView.swift
//  Hackchat
//
//  Created by Liam Willey on 4/21/25.
//

import SwiftUI

struct ChatRowView: View {
    private let chat: Chat
    private let icon: String?
    private let showChevron: Bool
    
    @State private var isResponding = false
    
    init(_ chat: Chat, icon: String? = nil, showChevron: Bool = true) {
        self.chat = chat
        self.icon = icon
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 7) {
            if let icon {
                Image(systemName: icon)
                    .fontWeight(.medium)
            }
            Text(chat.name ?? "Untitled")
                .lineLimit(1)
                .fontWeight(.semibold)
            Spacer()
//            if isResponding {
//                ProgressView()
//            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .onChange(of: chat) { _, chat in
            self.isResponding = chat.isResponding
        }
    }
}
