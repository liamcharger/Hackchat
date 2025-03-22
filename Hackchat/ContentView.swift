//
//  ContentView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("showWelcomeView") private var showWelcomeView = true
    
    @State private var isWelcoming = true
    
    var body: some View {
        Group {
            if isWelcoming {
                WelcomeView()
                    .transition(.blurReplace)
            } else {
                MainView()
                    .transition(.blurReplace)
            }
        }
        // We need to use onAppear and onChange for the transition to work properly
        .onChange(of: showWelcomeView) {
            withAnimation(.bouncy(duration: 0.9)) {
                isWelcoming = showWelcomeView
            }
        }
        .onAppear {
            isWelcoming = showWelcomeView
        }
    }
}

#Preview {
    ContentView()
}
