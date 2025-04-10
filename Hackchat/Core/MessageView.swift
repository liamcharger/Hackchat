//
//  MessageView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/21/25.
//

import SwiftUI
import MarkdownUI

struct MessageView: View {
    let message: Message
    let geo: GeometryProxy
    
    @State private var showDeleteConfirmation = false
    
    init(_ message: Message, geometry: GeometryProxy) {
        self.message = message
        self.geo = geometry
    }
    
    private func delete() {
        if let chat = message.chat {
            chat.removeFromMessages(message)
        }
    }
    
    var body: some View {
        let alignment = message.role == "user" ? Alignment.trailing : Alignment.leading
        
        Markdown(message.content ?? " ")
            .padding(9)
            .padding(.horizontal, 3)
            .foregroundColor(message.role == "user" ? .white : .primary)
            .background(message.role == "user" ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Material.ultraThin))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(maxWidth: geo.size.width / 1.35, alignment: alignment)
            .contextMenu {
                if let role = message.role, role == "user" {
                    Button {
                        
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .frame(maxWidth: .infinity, alignment: alignment)
            .confirmationDialog("Are you sure you want to delete a message? This action cannot be undone.", isPresented: $showDeleteConfirmation) {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Text("Delete")
                }
            }
    }
}
