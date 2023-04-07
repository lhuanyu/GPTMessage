//
//  Conversation.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

enum MessageType {
    case text
    case image
    case imageData
    case error
}

struct Conversation: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var isReplying: Bool = false
    
    var isLast: Bool = false
    
    var input: String
    
    var reply: String?
    
    var errorDesc: String?
    
    var date = Date()
    
    var replyPreview: String? {
        if replyType == .image || replyType == .imageData {
            return String(localized: "[Image]")
        }
        return reply
    }
    
    var replyType: MessageType {
        guard errorDesc == nil else {
            return .error
        }
        guard let reply = reply else {
            return .error
        }
        if reply.hasPrefix("![Image]") {
            return .image
        } else if reply.hasPrefix("![ImageData]") {
            return .imageData
        }
        return .text
    }
    
    var replyImageURL: URL? {
        guard replyType == .image else {
            return nil
        }
        guard let reply = reply else {
            return nil
        }
        let path = String(reply.deletingPrefix("![Image](").dropLast())
        return URL(string: path)
    }
    
    var replyImageData: Data? {
        guard replyType == .imageData else {
            return nil
        }
        guard let reply = reply else {
            return nil
        }
        let base64 = String(reply.deletingPrefix("![ImageData](data:image/png;base64,").dropLast())
        return Data(base64Encoded: base64)
    }
}
