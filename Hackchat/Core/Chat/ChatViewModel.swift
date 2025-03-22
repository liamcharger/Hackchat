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
    
    @Published var chat: Chat
    
    init(_ chat: Chat) {
        self.chat = chat
    }
    
    var isResponding: Bool {
        return chat.isResponding
    }
    
    func sendMessage(message: String) {
        // Cancel any messages that were already sending
        cancelMessage()
        chat.isResponding = true
        
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
        let body: [String: Any] = [
            "messages": messages
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        messageTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print(error.localizedDescription)
                return
            }
            
            guard let data = data else { return }
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(Response.self, from: data)
                
                DispatchQueue.main.async {
                    // Occasionally we may get more than one choice
                    // TODO: add support for more than one message to be displayed?
                    guard let first = response.choices.first else {
                        print("There were no message choices")
                        return
                    }
                    
                    // TODO: add support for streaming
                    // Handle other errors: timeout, message too long, etc.
                    if first.finish_reason != "stop" {
                        print(first)
                    }
                    
                    let newMessage = Message(context: self.coreDataManager.persistentContainer.viewContext)
                    newMessage.id = UUID()
                    newMessage.chat = self.chat
                    newMessage.content = first.message.content
                    newMessage.role = first.message.role
                    newMessage.timestamp = Date()
                    
                    self.chat.addToMessages(newMessage)
                    self.chat.isResponding = false
                    
                    self.coreDataManager.save()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        messageTask?.resume()
    }
    
    func cancelMessage() {
        messageTask?.cancel()
        chat.isResponding = false
    }
}
