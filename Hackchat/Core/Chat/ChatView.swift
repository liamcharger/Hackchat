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
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject private var chatViewModel: ChatViewModel
    @ObservedObject private var networkManager = NetworkManager.shared
    @ObservedObject private var coreDataManager = CoreDataManager.shared
    @ObservedObject private var mainViewModel = MainViewModel.shared
    
    @FetchRequest(entity: Chat.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Chat.timestamp, ascending: false)]) private var chats: FetchedResults<Chat>
    
    @State private var message: String = ""
    @State private var chatName: String = ""
    @State private var isEditingName: Bool = false
    @State private var showCustomInstructionsView: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showSameNameError: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var error: String?
    @State private var selectedMessage: Message?
    @State private var messageToEdit: Message?
    @State private var promptSuggestions = [ChatSuggestion]()
    @State private var messageFieldHeight: CGFloat = 0
    @State private var nameFieldHeight: CGFloat = 0
    
    @FocusState private var messageFieldIsFocused: Bool
    @FocusState private var nameFieldIsFocused: Bool
    
    private let animation: Animation = .smooth(duration: 0.3)
    private let preview: Bool
    private let isArchived: Bool
    
    private func sendMessage() {
        guard !message.isEmpty else { return }
        
        scrollToBottom()
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
                withAnimation(.smooth) {
                    scroll()
                }
            } else {
                scroll()
            }
        }
    }
    private func startRenaming() {
        chatName = chatViewModel.chat.name ?? ""
        playHaptic()
        nameFieldIsFocused = true
        withAnimation(animation) {
            isEditingName = true
        }
    }
    private func startEditingMessage() {
        guard let messageToEdit else { return }
        
        message = messageToEdit.content ?? ""
        messageFieldIsFocused = true
    }
    
    init(_ chat: Chat, preview: Bool = false, isArchived: Bool = false) {
        self.chatViewModel = ChatViewModel(chat)
        self.preview = preview
        self.isArchived = isArchived
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if !preview {
                    HStack(spacing: 16) {
                        if isArchived {
                            Button("Cancel") {
                                dismiss()
                            }
                        } else {
                            NavigationBarButton("arrow.left") { dismiss() }
                        }
                        Spacer()
                        if isArchived {
                            NavigationBarButton("arrow.uturn.left") {
                                dismiss()
                                mainViewModel.archiveChat(chatViewModel.chat)
                            }
                            NavigationBarButton("trash") {
                                dismiss()
                                // TODO: confirmation
                                mainViewModel.deleteChat(chatViewModel.chat)
                            }
                            .foregroundStyle(.red)
                        } else {
                            Menu {
                                if !isEditingName {
                                    Button {
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
                                Button {
                                    playHaptic()
                                    dismiss()
                                    mainViewModel.archiveChat(chatViewModel.chat)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                Button(role: .destructive) {
                                    playHaptic()
                                    dismiss()
                                    // TODO: confirmation
                                    mainViewModel.deleteChat(chatViewModel.chat)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "info.circle")
                                    .imageScale(.large)
                                    .fontWeight(.medium)
                            }
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
                                    .frame(width: isEditingName ? geo.size.width / 1.7 : nil)
                                    .onHeightChange { height in
                                        self.nameFieldHeight = height
                                    }
                                    .padding(8)
                                    .background(Color(.systemBackground))
                                    .clipShape(.rect(cornerRadius: 15))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(showSameNameError ? AnyShapeStyle(Color.red) : AnyShapeStyle(Material.regular), lineWidth: 1.5)
                                    }
                                    .submitLabel(.done)
                                    .onSubmit {
                                        guard !showSameNameError else {
                                            // There's already a chat with the inputted name
                                            // An error will be displayed, so don't do anything
                                            nameFieldIsFocused = true
                                            return
                                        }
                                        
                                        // TODO: just don't allow empty names
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
                                    .onChange(of: chatName) { _, name in
                                        withAnimation(animation) {
                                            showSameNameError = chats.first(where: { ($0.name ?? "") == name && $0.id != chatViewModel.chat.id }) != nil
                                        }
                                    }
                                    .background(alignment: .top) {
                                        VStack(spacing: 0) {
                                            if showSameNameError {
                                                Color.clear // Push the banner below the TextField
                                                    .frame(height: nameFieldHeight)
                                            }
                                            Text("There's already another chat with this name")
                                                .frame(minHeight: 45, alignment: .leading)
                                        }
                                        .compositingGroup()
                                        .frame(width: geo.size.width / 1.7)
                                        .padding(8)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.red)
                                        .background(Color("OpaqueRed"))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                        .clipShape(
                                            .rect(
                                                topLeadingRadius: 15,
                                                bottomLeadingRadius: 20,
                                                bottomTrailingRadius: 20,
                                                topTrailingRadius: 15
                                            )
                                        )
                                        .opacity(showSameNameError ? 1 : 0)
                                    }
                            } else {
                                Text(chatName)
                                    .onLongPressGesture(perform: startRenaming)
                                    .onTapGesture(count: 2, perform: startRenaming)
                            }
                        }
                        .fontWeight(.semibold)
                    }
                    .zIndex(999)
                    Divider()
                }
                Group {
                    if chatViewModel.messages.count <= 0 {
                        InfoMessageView(title: "Nothing here yet...send a message to start the chat.")
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 2) {
                                    VStack(spacing: 10) {
                                        if !preview && !isArchived {
                                            Text("Don't share passwords or other sensitive information in this chat.")
                                                .italic()
                                        }
                                        if let timestamp = chatViewModel.chat.timestamp {
                                            Text(timestamp.formatted())
                                        }
                                    }
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 17))
                                    .foregroundStyle(.gray)
                                    .padding(.bottom)
                                    
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
                                                        playHaptic()
                                                        withAnimation(animation) {
                                                            messageToEdit = message
                                                        }
                                                        startEditingMessage()
                                                    } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }
                                                    Button {
                                                        playHaptic()
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
                                            // preview: {
                                            // TODO: complete
                                            //     Markdown(message.content ?? " ")
                                            //         .lineLimit(15)
                                            // }
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
                                                    
                                                    // Don't add padding if the messages are less than a minute apart
                                                    let elapsedSeconds = (now - previous)
                                                    if elapsedSeconds < 60 {
                                                        return 0
                                                    }
                                                }
                                                
                                                // If this falls through, the elapsed seconds are either more than 60 or the messages were sent from different roles
                                                return padding
                                            }())
                                    }
                                    if chatViewModel.isResponding {
                                        ProgressView()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    // This is the anchor we use to scroll to the bottom of the ScrollView each time a message is sent
                                    // Use this instead of assigning an id to each message because the scroll animations don't work properly
                                    Color.clear
                                        .frame(height: 1)
                                        .id("bottom")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            .defaultScrollAnchor(.bottom)
                            .scrollDismissesKeyboard(.interactively)
                            .onAppear {
                                self.scrollProxy = proxy
                            }
                        }
                    }
                }
                .transition(.slide)
                if !preview && !isArchived {
                    Divider()
                    VStack(spacing: 12) {
                        if chatViewModel.messages.isEmpty && message.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(promptSuggestions) { suggestion in
                                        Button {
                                            playHaptic()
                                            chatViewModel.sendMessage(message: suggestion.title + " " + suggestion.subtitle + ".")
                                        } label: {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .foregroundStyle(Color.primary)
                                                    .fontWeight(.semibold)
                                                Text(suggestion.subtitle)
                                                    .foregroundStyle(.gray)
                                            }
                                            .padding(12)
                                            .frame(minWidth: 200, alignment: .leading)
                                            .background(Material.ultraThin)
                                            .clipShape(.rect(cornerRadius: 15))
                                            .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                            .padding(.horizontal, -12)
                            .compositingGroup()
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(animation, value: chatViewModel.messages.isEmpty && message.isEmpty)
                        }
                        ZStack(alignment: .bottom) {
                            VStack(spacing: 0) {
                                HStack {
                                    if messageToEdit != nil {
                                        Text("Editing message")
                                    } else if let error {
                                        Text(error)
                                    }
                                    Spacer()
                                    Button {
                                        withAnimation(animation) {
                                            chatViewModel.error = nil
                                            message = ""
                                            messageToEdit = nil
                                        }
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                    .buttonStyle(DepressedButtonStyle())
                                }
                                .fontWeight(.semibold)
                                .padding(12)
                                if error != nil || messageToEdit != nil {
                                    Color.clear // Push the banner to the top the TextField
                                        .frame(height: messageFieldHeight)
                                        .transition(.move(edge: .bottom))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle({
                                if messageToEdit != nil {
                                    return Color.blue
                                } else if error != nil {
                                    return Color.red
                                }
                                return Color.clear
                            }())
                            .background({
                                if messageToEdit != nil {
                                    return Color("OpaqueBlue")
                                } else if error != nil {
                                    return Color("OpaqueRed")
                                }
                                return Color.clear
                            }())
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 15,
                                    bottomLeadingRadius: 24,
                                    bottomTrailingRadius: 24,
                                    topTrailingRadius: 15
                                )
                            )
                            .opacity(messageToEdit != nil || error != nil ? 1 : 0)
                            HStack {
                                TextField("Message...", text: $message, axis: .vertical)
                                    .focused($messageFieldIsFocused)
                                    .lineLimit(5)
                                    .padding(.leading, 7)
                                    .disabled(chatViewModel.isResponding)
                                    .onChange(of: message) { _, message in
                                        guard messageToEdit == nil else { return } // Don't save the message we might be editing as a draft
                                        
                                        chatViewModel.chat.draft = message // This is saved in onDisappear
                                    }
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
                                .disabled(message.isEmpty && !chatViewModel.isResponding)
                                .opacity((message.isEmpty && !chatViewModel.isResponding) ? 0.5 : 1)
                            }
                            .padding(8)
                            .background(Color("GrayBackground"))
                            .clipShape(.rect(cornerRadius: 24))
                            .onTapGesture {
                                messageFieldIsFocused = true
                            }
                            .onHeightChange { height in
                                self.messageFieldHeight = (height - 16) // Compensate for extra space aroud the frame
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                }
            }
            // TODO: add animation to scroll view
        }
        .compositingGroup()
        .transition(.move(edge: .top))
        .ignoresSafeArea(isEditingName ? [.keyboard] : []) // Don't push the message field and/or banners up when we're editing the name
        .confirmationDialog("Delete Message", isPresented: $showDeleteConfirmation, actions: {
            Button(role: .destructive) {
                guard let message = selectedMessage else { return }
                
                playHaptic()
                chatViewModel.deleteMessage(message)
            } label: {
                Text("Delete")
            }
        }, message: {
            Text("Are you sure you want to delete a message? This action cannot be undone.")
        })
        .onChange(of: chatViewModel.error) { _, error in
            // Use private property instead of chatViewModel.error so we can set an animation whenever the latter is set
            withAnimation(animation) {
                self.error = error
            }
        }
        .onChange(of: chatViewModel.chat.name) { _, createdName in
            self.chatName = createdName ?? "Untitled"
        }
        .onChange(of: networkManager.connected) { _, _ in
            // When the "messages cannot be sent" banner appears, it will cover some messages unless we scroll
            scrollToBottom()
        }
        .onChange(of: chatViewModel.messages) { _, messages in
            // Scroll whenever a message is sent
            scrollToBottom()
        }
        .onAppear {
            if let draft = chatViewModel.chat.draft {
                // The user never finished their message
                message = draft
            }
            // Return a random selection of three suggestions
            promptSuggestions = Array(chatViewModel.suggestions.shuffled()[0..<4])
            chatName = chatViewModel.chat.name ?? "Untitled"
            // If the view model reinitializes, set the error state again
            error = chatViewModel.error
        }
        .onDisappear {
            // FIXME: make sure this is sufficient to save the user's draft, accounting for crashes and force closes
            coreDataManager.save()
            // Dismiss all keyboards
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
    ChatView(Chat(context: CoreDataManager.shared.persistentContainer.viewContext))
}
