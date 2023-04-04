//
//  Conversation.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

struct Conversation: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var isReplying: Bool = false
    
    var isLast: Bool = false
    
    var input: String
    
    var reply: String?
    
    var errorDesc: String?
    
    var date = Date()
    
    var replyPreview: String? {
        if isImageReply {
            return String(localized: "[Image]")
        }
        return reply
    }
    
    var isImageReply: Bool {
        if let reply = reply {
            return reply.hasPrefix("![Image]")
        }
        return false
    }
    
    var replyImageURL: URL? {
        guard let reply = reply else {
            return nil
        }
        let path = String(reply.deletingPrefix("![Image](").dropLast())
        return URL(string: path)
    }
    
}
