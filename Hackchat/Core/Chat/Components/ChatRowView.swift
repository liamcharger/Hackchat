//
//  ChatRowView.swift
//  Hackchat
//
//  Created by Liam Willey on 4/21/25.
//

import SwiftUI

struct ChatRowView: View {
    private let key: String
    private let icon: String?
    private let showChevron: Bool
    
    init(_ key: String, icon: String? = nil, showChevron: Bool = true) {
        self.key = key
        self.icon = icon
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 7) {
            if let icon {
                Image(systemName: icon)
                    .fontWeight(.medium)
            }
            Text(key)
                .lineLimit(1)
                .fontWeight(.semibold)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}
