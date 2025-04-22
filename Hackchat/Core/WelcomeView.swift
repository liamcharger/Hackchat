//
//  WelcomeView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.openURL) var openURL
    
    @AppStorage("showWelcomeView") private var showWelcomeView = true
    
    @State private var showMoreError = false
    
    func safeAreaInsets() -> CGFloat {
#if os(iOS)
        if let window = UIApplication.shared.windows.first {
            let inset = window.safeAreaInsets.top
            return inset
        }
#endif
        return 0
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 18) {
                Spacer()
                VStack(spacing: 10) {
                    Text("Welcome to Hackchat!")
                        .font(.largeTitle.weight(.bold))
                    Text("A free app for hackclubbers to chat with AI models")
                        .opacity(0.75)
                }
                Button {
                    showWelcomeView.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                    .padding(14)
                    .fontWeight(.medium)
                    .background(Color.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .depressedButtonStyle()
                Spacer()
                Group {
                    Text("Don't know what Hack Club is? ")
                        .foregroundStyle(.secondary)
                    + Text("Learn More")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
                .onTapGesture {
                    guard let url = URL(string: "https://hackclub.com") else { return }
#if os(iOS)
                    if UIApplication.shared.canOpenURL(url) {
                        openURL(url)
                    } else {
                        showMoreError = true
                    }
#else
                    openURL(url)
#endif
                }
                .alert("The URL couldn't be opened", isPresented: $showMoreError) {}
            }
            .multilineTextAlignment(.center)
            .padding()
            Image("orpheus-flag")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 110)
                .offset(x: 0, y: -safeAreaInsets())
        }
    }
}

#Preview {
    WelcomeView()
}
