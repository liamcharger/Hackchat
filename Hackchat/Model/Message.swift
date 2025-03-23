//
//  Message.swift
//  Hackchat
//
//  Created by Liam Willey on 3/20/25.
//

import Foundation

struct ResponseMessage: Codable, Equatable {
    var role: String?
    var content: String?
}

struct Response: Codable {
    let choices: [MessageChoice]
    let created: Int
    let id: String
    let model: String
    let object: String
    let system_fingerprint: String
    let x_groq: XGroq?
}

struct MessageChoice: Codable {
    let delta: ResponseMessage?
    let finish_reason: String?
    let index: Int
}

struct XGroq: Codable {
    let id: String
    let usage: XGroqUsage?
}

struct XGroqUsage: Codable {
    let completion_time: Double
    let completion_tokens: Int
    let prompt_time: Double
    let prompt_tokens: Int
    let total_time: Double
    let total_tokens: Int
}
