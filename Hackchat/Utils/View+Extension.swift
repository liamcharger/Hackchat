//
//  View+Extension.swift
//  Hackchat
//
//  Created by Liam Willey on 4/15/25.
//

import Foundation
import SwiftUI

struct ViewHeightModifier: ViewModifier {
    let padding: CGFloat
    let completion: (CGFloat) -> Void
    
    init(with padding: CGFloat = 0, completion: @escaping (CGFloat) -> Void) {
        self.padding = padding
        self.completion = completion
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            completion(geo.size.height + padding)
                        }
                        .onChange(of: geo.size.height) { _, newHeight in
                            completion(newHeight + padding)
                        }
                }
            )
    }
}

extension View {
    public func onHeightChange(withPadding padding: CGFloat = 16, perform action: @escaping (CGFloat) -> Void) -> some View {
        modifier(ViewHeightModifier(with: padding, completion: action))
    }
}
