//
//  DepressedButtonStyle.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

struct DepressedButtonStyle: ButtonStyle {
    let depth: CGFloat
    let vibrationStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    init(depth: CGFloat = 0.9, vibrationStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        self.depth = depth
        self.vibrationStyle = vibrationStyle
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? depth : 1)
            .animation(.bouncy(duration: 0.3), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if !isPressed {
                    UIImpactFeedbackGenerator(style: vibrationStyle).impactOccurred()
                }
            }
    }
}

extension View {
    func depressedButtonStyle(_ depth: CGFloat = 0.9) -> some View {
        self
            .buttonStyle(DepressedButtonStyle(depth: depth))
    }
}
