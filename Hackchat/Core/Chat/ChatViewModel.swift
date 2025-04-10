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
    
    @Published var chat: Chat
    @Published var error: String?
    
    init(_ chat: Chat) {
        self.chat = chat
    }
    
    var isResponding: Bool {
        return chat.isResponding
    }
    
    func sendMessage(message: String) {
        // Cancel any messages that were already sending
        cancelMessage(setState: false)
        chat.isResponding = true
        isCancelled = false
        
        let newMessage = Message(context: coreDataManager.persistentContainer.viewContext)
        newMessage.id = UUID()
        newMessage.chat = chat
        newMessage.content = message
        newMessage.role = "user"
        newMessage.timestamp = Date()
        chat.addToMessages(newMessage)
        
        self.coreDataManager.save()
        
        var request = URLRequest(url: URL(string: "https://ai.hackclub.com/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        messageTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error.localizedDescription
                return
            }
            
            guard let data = data, let jsonString = String(data: data, encoding: .utf8) else {
                self.error = unknownError()
                print("Failed to decode response as a string")
                return
            }
            
            let lines = jsonString.split(separator: "\n")
            let decoder = JSONDecoder()
            
            for line in lines {
                guard let jsonData = line.data(using: .utf8) else { continue }
                
                print(String(data: jsonData, encoding: .utf8)!)
                
                do {
                    let responseChunk = try decoder.decode(Response.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        guard let first = responseChunk.choices.first else {
                            self.error = self.unknownError()
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
                    self.error = unknownError()
                    print("Failed to decode chunk:", error)
                }
            }
        }
        
        messageTask?.resume()
    }
    
    func cancelMessage(setState: Bool = true) {
        if setState {
            setCancelledState()
        }
        messageTask?.cancel()
        messageTask = nil
    }
    
    private func setCancelledState() {
        isCancelled = true
        chat.isResponding = false
    }
    
    private func appendStreamingText(_ delta: ResponseMessage, id: UUID) {
        guard let content = delta.content else { return }
        guard !self.isCancelled && !content.isEmpty else { return }

        let existingMessage = self.chat.messages.array().first(where: { $0.id == id })
        
        // Update the existing message or start a new one
        if let existingMessage = existingMessage {
            let currentContent = existingMessage.content ?? ""
            existingMessage.content = currentContent + content
        } else {
            let newMessage = Message(context: self.coreDataManager.persistentContainer.viewContext)
            newMessage.id = id
            newMessage.chat = self.chat
            newMessage.content = delta.content
            newMessage.role = "assistant"
            newMessage.timestamp = Date()
            
            self.chat.addToMessages(newMessage)
        }

        self.coreDataManager.save()
    }
    
    private func unknownError() -> String {
        return NSLocalizedString("unknown_error", comment: "")
    }
}
