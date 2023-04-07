//
//  Models.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import Foundation

///Completion
struct Command: Encodable {
    let prompt: String
    let model: String
    let maxTokens: Int
    let temperature: Double
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case prompt
        case model
        case maxTokens = "max_tokens"
        case temperature
        case stream
    }
}

///Edit
struct Instruction: Encodable {
    let instruction: String
    let model: String
    let input: String
}

///Chat
struct Message: Codable {
    let role: String
    let content: String
}

extension Character {
    var isChinese: Bool {
        for scalar in unicodeScalars {
            if !(0x4E00...0x9FA5).contains(scalar.value) {
                return false
            }
        }
        return true
    }

}

extension String {
    
    var token: Int {
        var count = 0.0
        for character in self {
            if character.isChinese {
                count += 1
            } else {
                count += 0.3
            }
        }
        return Int(count)
    }
    
}

extension Array where Element == Message {
    
    var tokenCount: Int {
        contentCount
    }
    
    var contentCount: Int { reduce(0, { $0 + $1.content.token })}
}

struct Chat: Codable {
    let model: String
    let temperature: Double
    let messages: [Message]
    let stream: Bool
}

struct ErrorRootResponse: Decodable {
    let error: ErrorResponse
}

struct ErrorResponse: Decodable {
    let message: String
    let type: String?
}

struct StreamCompletionResponse: Decodable {
    let choices: [StreamChoice]
}

struct StreamResponse<ChoiceType: Decodable>: Decodable {
    let choices: [ChoiceType]
}

struct CompletionResponse: Decodable {
    let choices: [Choice]
    let usage: Usage?
}

struct Usage: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
}

struct TextChoice: Decodable {
    let text: String
    let finishReason: String?
}

struct Choice: Decodable {
    let message: Message
    let finishReason: String?
}

struct StreamChoice: Decodable {
    let finishReason: String?
    let delta: StreamMessage
}

struct StreamMessage: Decodable {
    let role: String?
    let content: String?
}

