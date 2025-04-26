//
//  NavigationBackButton.swift
//  Hackchat
//
//  Created by Liam Willey on 4/22/25.
//

import SwiftUI

struct NavigationBackButton: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationBarButton("arrow.left", alignment: .leading) {
            dismiss()
        }
    }
}

#Preview {
    NavigationBackButton()
}
