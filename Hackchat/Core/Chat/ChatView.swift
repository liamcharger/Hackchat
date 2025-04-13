//
//  ChatView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import SwiftUI
import MarkdownUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var chatViewModel: ChatViewModel
    @ObservedObject private var networkManager = NetworkManager.shared
    @ObservedObject private var coreDataManager = CoreDataManager.shared
    
    @FetchRequest(entity: Chat.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Chat.timestamp, ascending: false)]) private var chats: FetchedResults<Chat>
    
    @State private var message: String = ""
    @State private var chatName: String = ""
    @State private var isEditingName: Bool = false
    @State private var showCustomInstructionsView: Bool = false
    @State private var showDeleteConfirmation = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var error: String?
    @State private var selectedMessage: Message?
    @State private var messageToEdit: Message?
    
    @FocusState private var messageFieldIsFocused: Bool
    @FocusState private var nameFieldIsFocused: Bool
    
    private let animation: Animation = .smooth(duration: 0.3)
    
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
    private func startRenaming() {
        chatName = chatViewModel.chat.name ?? ""
        playHaptic(style: .medium)
        nameFieldIsFocused = true
        withAnimation(animation) {
            isEditingName = true
        }
    }
    private func startEditingMessage() {
        guard let messageToEdit else { return }
        
        message = messageToEdit.content ?? "No content"
        messageFieldIsFocused = true
    }

    init(chat: Chat) {
        chatViewModel = ChatViewModel(chat)
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack {
                    NavigationBarButton("arrow.left") {
                        dismiss()
                    }
                    Spacer()
                    Menu {
                        if !isEditingName {
                            Button {
                                playHaptic()
                                startRenaming()
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                        }
                        Button {
                            playHaptic()
                            showCustomInstructionsView = true
                        } label: {
                            Label("Custom Instructions", systemImage: "hammer")
                        }
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
                .padding(12)
                .overlay {
                    VStack {
                        if isEditingName {
                            TextField("Chat Name", text: $chatName)
                                .focused($nameFieldIsFocused)
                                .frame(width: isEditingName ? geo.size.width / 2.3 : nil)
                                .padding(8)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Material.regular, lineWidth: 1.5)
                                }
                                .submitLabel(.done)
                                .onChange(of: chatName) { _, name in
                                    if chats.first(where: { ($0.name ?? "") == name }) != nil {
                                        chatViewModel.error = "A chat with that name already exists."
                                    } else {
                                        chatViewModel.error = nil
                                    }
                                }
                                .onSubmit {
                                    guard !(error ?? "").contains("name already exists") else {
                                        nameFieldIsFocused = true
                                        return
                                    }
                                            
                                    if chatName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        let untitledString = "Untitled"
                                        let untitledChats = chats.filter({ ($0.name ?? "").contains(untitledString) })
                                        
                                        let count = untitledChats.count
                                        if count >= 1 {
                                            let count = count + 1 // Count up one more so there isn't more than one chat with the same number
                                            chatViewModel.updateChatName("\(untitledString) \(count)")
                                        } else {
                                            chatViewModel.updateChatName(untitledString)
                                        }
                                    } else {
                                        chatViewModel.updateChatName(chatName)
                                    }
                                    withAnimation(animation) {
                                        isEditingName = false
                                    }
                                }
                        } else {
                            Text(chatName)
                                .onLongPressGesture(perform: startRenaming)
                                .onTapGesture(count: 2, perform: startRenaming)
                        }
                    }
                    .compositingGroup()
                    .transition(.slide)
                    .fontWeight(.semibold)
                }
                Divider()
                Group {
                    if chatViewModel.messages.count <= 0 {
                        InfoMessageView(title: "Nothing here yet...send a message to start the chat.")
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 2) {
                                    let messages = chatViewModel.messages.filter { $0.role != "system" }
                                    ForEach(messages.indices, id: \.self) { index in
                                        let previousMessage = messages.indices.contains(index - 1) ? messages[index - 1] : nil
                                        let message = messages[index]
                                        let alignment = message.role == "user" ? Alignment.trailing : Alignment.leading
                                        
                                        Markdown(message.content ?? " ")
                                            .padding(9)
                                            .padding(.horizontal, 3)
                                            .foregroundColor(message.role == "user" ? .white : .primary)
                                            .background(message.role == "user" ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Material.ultraThin))
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .frame(maxWidth: geo.size.width / 1.35, alignment: alignment)
                                            .contextMenu {
                                                if let role = message.role, role == "user" {
                                                    Button {
                                                        messageToEdit = message
                                                        startEditingMessage()
                                                    } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }
                                                    Button {
                                                        selectedMessage = message
                                                        chatViewModel.regenerateResponse(from: selectedMessage!)
                                                    } label: {
                                                        Label("Resend", systemImage: "arrow.uturn.forward")
                                                    }
                                                }
                                                Button(role: .destructive) {
                                                    selectedMessage = message
                                                    showDeleteConfirmation = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: alignment)
                                            .padding(.top, {
                                                let padding: CGFloat = 5
                                                
                                                // If there isn't a message above, then it's the first message and doesn't need any padding
                                                guard let previousMessage else { return 0 }
                                                
                                                guard let previousRole = previousMessage.role else { return padding }
                                                guard let role = message.role else { return padding }
                                                
                                                if previousRole == role {
                                                    // These will not be nil
                                                    guard let timestamp = message.timestamp else { return 0 }
                                                    guard let previousTimestamp = previousMessage.timestamp else { return 0 }
                                                    
                                                    let now = timestamp.timeIntervalSince1970
                                                    let previous = previousTimestamp.timeIntervalSince1970
                                                    
                                                    // Check if the timestamps are close
                                                    let elapsedSeconds = (now - previous)
                                                    if elapsedSeconds < 60 {
                                                        return 0
                                                    }
                                                }
                                                
                                                // The elapsed seconds are either more than 60 or the messages were sent from different roles
                                                return padding
                                            }())
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
                            .scrollDismissesKeyboard(.interactively)
                            .onAppear {
                                self.scrollProxy = proxy
                            }
                        }
                    }
                }
                .transition(.slide)
                Divider()
                VStack(spacing: 12) {
                    Group {
                        let banner: Banner? = {
                            if let error {
                                return Banner(title: "\(error)", icon: "exclamationmark.circle", type: .error)
                            } else if !networkManager.connected {
                                return Banner(title: "Messages cannot be sent", icon: "wifi.slash", subtitle: "Your internet connection appears to be offline.")
                            }
                            return nil
                        }()
                        
                        if let banner {
                            ChatBannerView(banner) {
                                chatViewModel.dismissError()
                            }
                        } else if chatViewModel.messages.isEmpty && message.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 3) {
                                    ForEach(chatViewModel.promptSuggestions, id: \.self) { suggestion in
                                        Button {
                                            messageFieldIsFocused = true
                                            message = suggestion + "."
                                        } label: {
                                            Text(suggestion)
                                                .padding(12)
                                                .background(Material.ultraThin)
                                                .foregroundStyle(.white.opacity(0.9))
                                                .clipShape(.rect(cornerRadius: 15))
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                                .frame(width: 260)
                                        }
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                            .padding(.horizontal, -12)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    if messageToEdit != nil {
                        // TODO: improve
                        HStack {
                            Text("Editing message")
                            Spacer()
                            Image(systemName: "xmark")
                                .onTapGesture {
                                    messageToEdit = nil
                                }
                        }
                    }
                    HStack {
                        TextField("Message...", text: $message, axis: .vertical)
                            .focused($messageFieldIsFocused)
                            .lineLimit(5)
                            .padding(.leading, 7)
                            .disabled(chatViewModel.isResponding)
                        Button {
                            if chatViewModel.isResponding {
                                self.chatViewModel.cancelMessage()
                            } else if let messageToEdit {
                                self.chatViewModel.editMessage(message, for: messageToEdit)
                                self.messageToEdit = nil
                                self.message = ""
                            } else {
                                self.sendMessage()
                            }
                        } label: {
                            Image(systemName: chatViewModel.isResponding ? "stop.fill" : (messageToEdit == nil ? "arrow.up" : "checkmark"))
                                .fontWeight(.semibold)
                                .padding(8)
                                .foregroundStyle(.white.gradient)
                                .background(Color.blue.gradient)
                                .clipShape(Circle())
                        }
                        .depressedButtonStyle(0.93)
                        .disabled((message.isEmpty && !chatViewModel.isResponding) || !networkManager.connected)
                        .opacity(((message.isEmpty && !chatViewModel.isResponding) || !networkManager.connected) ? 0.5 : 1)
                    }
                    .padding(8)
                    .background(Material.regular)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .onTapGesture {
                        messageFieldIsFocused = true
                    }
                }
                .padding(12)
            }
        }
        .confirmationDialog("Are you sure you want to delete a message? This action cannot be undone.", isPresented: $showDeleteConfirmation) {
            Button(role: .destructive) {
                guard let message = selectedMessage else { return }
                
                chatViewModel.deleteMessage(message)
            } label: {
                Text("Delete")
            }
        }
        .onChange(of: chatViewModel.error) { _, error in
            // Use private property instead of chatViewModel.error so we can set an animation whenever the latter is set
            withAnimation(animation) {
                self.error = error
            }
        }
        .onChange(of: chatViewModel.chat) { _, chat in
            self.chatName = chat.name ?? "Untitled"
        }
        .onChange(of: chatViewModel.messages) { _, messages in
            scrollToBottom()
            
            // Make sure we haven't already set the name once
            if !chatViewModel.chat.hasSetGeneratedName && messages.count <= 2 {
                // The first messages from both sides have been sent, create a chat name
                chatViewModel.getChatName()
            }
        }
        .onAppear {
            chatName = chatViewModel.chat.name ?? "Untitled"
            // If the view model reinitializes, set the error state again
            error = chatViewModel.error
            // When the user opens the chat for the first time, it should open to the latest message
            scrollToBottom(animate: false)
        }
        .onDisappear {
            nameFieldIsFocused = false
            withAnimation(animation) {
                isEditingName = false
            }
        }
        .sheet(isPresented: $showCustomInstructionsView) {
            CustomInstructionsView(chat: chatViewModel.chat)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ChatView(chat: Chat(context: CoreDataManager.shared.persistentContainer.viewContext))
}
