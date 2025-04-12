//
//  InfoMessageView.swift
//  Hackchat
//
//  Created by Liam Willey on 4/12/25.
//

import SwiftUI

struct InfoMessageView: View {
    let imageName: String
    let message: LocalizedStringKey
    let description: LocalizedStringKey?
    
    init(title: LocalizedStringKey, description: LocalizedStringKey? = nil, icon imageName: String = "circle.slash") {
        self.imageName = imageName
        self.message = title
        self.description = description
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: imageName)
                .font(.largeTitle.weight(.medium))
                .foregroundStyle(.gray)
            Text(message)
                .font(.title3.weight(description == nil ? .semibold : .bold))
                .foregroundStyle(description == nil ? .gray : .primary)
            if let description {
                Text(description)
                    .foregroundStyle(.gray)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
        // Add some extra border space
        .padding(20)
    }
}
