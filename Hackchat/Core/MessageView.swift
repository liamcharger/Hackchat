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
    
    init(_ message: Message, geometry: GeometryProxy) {
        self.message = message
        self.geo = geometry
    }
    
    var body: some View {
        let alignment = message.role == "user" ? Alignment.trailing : Alignment.leading
        
        Markdown(message.content ?? "")
            .padding(9)
            .padding(.horizontal, 3)
            .foregroundStyle(message.role == "user" ? .white : .primary)
            .background(message.role == "user" ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Material.ultraThin))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(maxWidth: geo.size.width / 1.35, alignment: alignment)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}
