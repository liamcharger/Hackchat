//
//  ChatView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var chatViewModel: ChatViewModel
    
    @State private var message: String = ""
    @State private var showCustomInstructionsView: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    
    @FocusState private var isFocused: Bool
    
    private func sendMessage() {
        guard !message.isEmpty else { return }
        
        chatViewModel.sendMessage(message: message)
        message = ""
    }
    private func scrollToBottom(animate: Bool = true) {
        func scroll() {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Delay to allow UI update
            // The scroll view will jump without scrolling unless we add this animation closure
            if animate {
                withAnimation {
                    scroll()
                }
            } else {
                scroll()
            }
        }
    }
    
    init(chat: Chat) {
        self.chatViewModel = ChatViewModel(chat)
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                NavigationBar(chatViewModel.chat.name ?? "Untitled") {
                    NavigationBarButton("arrow.left") {
                        dismiss()
                    }
                    Spacer()
                    Text(chatViewModel.chat.name ?? "Untitled")
                        .fontWeight(.semibold)
                    Spacer()
                    Menu {
                        Button {
                            showCustomInstructionsView = true
                        } label: {
                            Label("Custom Instructions", systemImage: "hammer")
                        }
                        // Use this style to add a vibration
                        .depressedButtonStyle()
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                            .fontWeight(.medium)
                    }
                }
                Divider()
                if let messages = chatViewModel.chat.messages, messages.count <= 0 {
                    VStack(spacing: 10) {
                        Image(systemName: "circle.slash")
                            .font(.largeTitle.weight(.medium))
                        Text("Nothing here yet...send a message to start the chat.")
                            .font(.title3.weight(.semibold))
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.gray)
                    .frame(maxHeight: .infinity)
                    // Add some extra space
                    .padding(20)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 2) {
                                let messages = chatViewModel.chat.messages.array().filter { $0.role != "system" }
                                ForEach(messages.indices, id: \.self) { index in
                                    let message = messages[index]
                                    MessageView(message, geometry: geo)
                                }
                                if chatViewModel.isResponding {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                // This is the anchor we use to scroll to the bottom of the ScrollView each time a message is sent
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .onAppear {
                            self.scrollProxy = proxy
                        }
                    }
                }
                Divider()
                HStack {
                    TextField(chatViewModel.isResponding ? "Generating..." : "Message...", text: $message)
                        .focused($isFocused)
                        .padding(.leading, 7)
                        .onSubmit {
                            // When the user presses the return key, the message will be sent
                            sendMessage()
                        }
                        .disabled(chatViewModel.isResponding)
                    Button {
                        if chatViewModel.isResponding {
                            chatViewModel.cancelMessage()
                        } else {
                            sendMessage()
                        }
                    } label: {
                        Image(systemName: chatViewModel.isResponding ? "stop.fill" : "arrow.up")
                            .fontWeight(.semibold)
                            .padding(8)
                            .foregroundStyle(.white.gradient)
                            .background(Color.blue.gradient)
                            .clipShape(Circle())
                    }
                    .depressedButtonStyle(0.93)
                    .disabled(message.isEmpty && !chatViewModel.isResponding)
                    .opacity(message.isEmpty && !chatViewModel.isResponding ? 0.5 : 1)
                }
                .padding(8)
                .background(Material.regular)
                .clipShape(Capsule())
                .onTapGesture {
                    isFocused = true
                }
                .padding(12)
            }
        }
        .onChange(of: chatViewModel.chat.messages.array()) {
            scrollToBottom()
        }
        .onAppear {
            scrollToBottom(animate: false)
            isFocused = true
        }
        .sheet(isPresented: $showCustomInstructionsView) {
            // TODO: create custom instructions view
        }
        .navigationBarBackButtonHidden()
    }
}
