//
//  ChatViewModel.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import CoreData
import SwiftUI

extension Optional where Wrapped == NSSet {
    func array() -> [Message] {
        if let set = self as? Set<Message> {
            let now = Date()
            return Array(set).sorted(by: { $0.timestamp ?? now < $1.timestamp ?? now })
        }
        return [Message]()
    }
}

class ChatViewModel: ObservableObject {
    let coreDataManager = CoreDataManager.shared
    
    private var messageTask: URLSessionDataTask?
    private var isCancelled: Bool = false
    private let suggestions = [
        "Recommend a new sci-fi movie with comedic elements",
        "List some meal ideas for a healthy dinner",
        "Create me a weekly workout plan for building muscle",
        "Recommend some Christmas gifts for a 6 year old",
        "Explain superconductors in simple terms",
        "Write a poem about Tom Cruise's favorite shoe brand"
    ]
    
    @Published var chat: Chat
    @Published var error: String?
    @Published var messages = [Message]()
    
    init(_ chat: Chat) {
        self.chat = chat
        self.error = chat.error
        
        self.saveMessages()
    }
    
    var isResponding: Bool {
        return chat.isResponding
    }
    var chatRequest: URLRequest {
        var request = URLRequest(url: URL(string: "https://ai.hackclub.com/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    var promptSuggestions: [String] {
        // Return a random selection of three suggestions
        return Array(suggestions.shuffled()[0..<3])
    }
    
    func sendMessage(message: String) {
        // Cancel any messages that were already sending and reset any errors
        cancelMessage(setState: false)
        dismissError()
        setChatEditedState()
        chat.isResponding = true
        isCancelled = false
        
        let newMessage = Message(context: coreDataManager.persistentContainer.viewContext)
        newMessage.id = UUID()
        newMessage.chat = chat
        newMessage.content = message
        newMessage.role = "user"
        newMessage.timestamp = Date()
        chat.addToMessages(newMessage)
        saveMessages()
        
        self.coreDataManager.save()
        
        // Add all the previous messages to the request for context
        var messages = [[String: String]]()
        // If there are custom instructions, add them to the request
        if let instructions = chat.customInstructions, !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(["role": "system", "content": instructions])
        }
        messages.append(contentsOf: chat.messages.array()
            .map { ["role": $0.role ?? "user", "content": $0.content ?? ""] })
        let messageId = UUID()
        let body: [String: Any] = [
            "messages": messages,
            "stream": true
        ]
        
        var request = self.chatRequest
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        messageTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                setError(error.localizedDescription)
                return
            }
            
            guard let data = data, let jsonString = String(data: data, encoding: .utf8) else {
                setError(unknownError())
                print("Failed to decode response as a string")
                return
            }
            
            let lines = jsonString.split(separator: "\n")
            let decoder = JSONDecoder()
            
            for line in lines {
                guard let jsonData = line.data(using: .utf8) else { continue }
                
                do {
                    let responseChunk = try decoder.decode(Response.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        guard let first = responseChunk.choices.first else {
                            self.setError(self.unknownError())
                            print("There were no message choices")
                            return
                        }
                        
                        if first.finish_reason == nil, let delta = first.delta {
                            self.appendStreamingText(delta, id: messageId)
                        } else {
                            self.cancelMessage()
                        }
                    }
                } catch {
                    setError(unknownError())
                    print("Failed to decode chunk:", error)
                }
            }
        }
        
        messageTask?.resume()
    }
    
    func getChatName() {
        var request = self.chatRequest
        
        // Add all the previous messages to the request for context
        var messages = [[String: String]]()
        messages.append(["role": "system", "content": "The messages in this chat are messages from another chat that you need to come up with a name for. Output strictly the name of the chat, nothing else."])
        messages.append(contentsOf: chat.messages.array()
            .map { ["role": $0.role ?? "user", "content": $0.content ?? ""] })
        
        // Stream so we don't have to change the Message model
        let body: [String: Any] = [
            "messages": messages,
            "stream": true
        ]
        var chatName = ""
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Don't do anything about error, this is a background request the user doesn't know is happening
            guard let self else { return }
            if let error {
                print(error.localizedDescription)
                return
            }
            guard let data = data, let jsonString = String(data: data, encoding: .utf8) else { return }
            
            let lines = jsonString.split(separator: "\n")
            let decoder = JSONDecoder()
            
            for line in lines {
                guard let jsonData = line.data(using: .utf8) else { continue }
                
                do {
                    let responseChunk = try decoder.decode(Response.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        guard let first = responseChunk.choices.first else { return }
                        
                        if first.finish_reason == nil, let delta = first.delta {
                            chatName += delta.content ?? ""
                        } else {
                            self.updateChatName(chatName, manual: false)
                        }
                    }
                } catch {
                    print("Failed to decode name chunk:", error)
                }
            }
        }.resume()
    }
    
    func updateChatName(_ name: String, manual: Bool = true) {
        DispatchQueue.main.async {
            self.coreDataManager.persistentContainer.viewContext.perform {
                self.chat.name = name
                
                if !manual {
                    self.chat.hasSetGeneratedName = true
                }
                
                self.setChatEditedState()
                self.coreDataManager.save()
            }
        }
    }
    
    func deleteMessage(_ message: Message) {
        DispatchQueue.main.async {
            self.coreDataManager.persistentContainer.viewContext.perform {
                self.chat.removeFromMessages(message)
                self.saveMessages()
            }
        }
    }
    
    func editMessage(_ content: String, for message: Message) {
        guard let index = self.chat.messages.array().firstIndex(of: message) else { return }
        
        // Remove all messages after the message to edit, and send the message again
        let messagesArray = Array(self.chat.messages.array()[..<index])
        self.chat.messages = NSSet(array: messagesArray)
        self.coreDataManager.save()
        self.saveMessages()
        self.sendMessage(message: content)
    }
    
    func cancelMessage(setState: Bool = true) {
        if setState {
            setCancelledState()
        }
        messageTask?.cancel()
        messageTask = nil
    }
    
    func dismissError() {
        DispatchQueue.main.async {
            self.coreDataManager.persistentContainer.viewContext.perform {
                self.chat.error = nil
                self.error = nil
                self.coreDataManager.save()
            }
        }
    }
    
    private func setChatEditedState() {
        // This moves the chat to the top of the list
        self.chat.lastEdited = Date()
        // We don't need to save the context because everywhere this function is being used already calls it
    }
    
    private func setError(_ error: String) {
        // The error "cancelled" is thrown if the user cancels a request by URLSession, so ignore it
        guard error != "cancelled" else { return }
        
        DispatchQueue.main.async {
            self.coreDataManager.persistentContainer.viewContext.perform {
                self.chat.error = error
                self.error = error
                self.cancelMessage()
                self.coreDataManager.save()
            }
        }
    }
    
    private func setCancelledState() {
        isCancelled = true
        chat.isResponding = false
    }
    
    private func appendStreamingText(_ delta: ResponseMessage, id: UUID) {
        guard let content = delta.content else { return }
        guard !self.isCancelled && !content.isEmpty else { return }

        let context = self.coreDataManager.persistentContainer.viewContext
        context.perform {
            let existingMessage = self.messages.first(where: { $0.id == id })

            if let existingMessage = existingMessage {
                let currentContent = existingMessage.content ?? ""
                existingMessage.content = currentContent + content
                
                // Also update the UI variable
                let messageInCollection = self.messages.firstIndex(of: existingMessage)
                if let messageInCollection {
                    self.messages[messageInCollection] = existingMessage
                }
            } else {
                let newMessage = Message(context: context)
                newMessage.id = id
                newMessage.chat = self.chat
                newMessage.content = content
                newMessage.role = "assistant"
                newMessage.timestamp = Date()
                
                self.chat.addToMessages(newMessage)
                self.saveMessages()
            }
            
            self.coreDataManager.save()
        }
    }
    
    private func saveMessages() {
        self.coreDataManager.save()
        self.messages = chat.messages.array()
    }
    
    private func unknownError() -> String {
        return NSLocalizedString("unknown_error", comment: "")
    }
}
