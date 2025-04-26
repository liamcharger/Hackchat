//
//  NavigationBarButton.swift
//  Hackchat
//
//  Created by Liam Willey on 4/22/25.
//

import SwiftUI

struct NavigationBarButton: View {
    let icon: String
    let alignment: NavigationAlignment
    let action: () -> Void
    
    init(_ icon: String, alignment: NavigationAlignment = .none, action: @escaping () -> Void) {
        self.icon = icon
        self.alignment = alignment
        self.action = action
    }
    
    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer()
            }
            Button {
                action()
            } label: {
                Image(systemName: icon)
                    .imageScale(.large)
                    .fontWeight(.medium)
            }
            .depressedButtonStyle()
            if alignment == .leading {
                Spacer()
            }
        }
    }
}
