//
//  HapticsManager.swift
//  Hackchat
//
//  Created by Liam Willey on 3/28/25.
//

import UIKit

func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}
