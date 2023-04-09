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
    
    
    var isImage: Bool {
        self == .image || self == .imageData
    }
}

struct Conversation: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var isReplying: Bool = false
    
    var isLast: Bool = false
    
    var input: String
    
    var inputData: Data?
    
    var reply: String?
    
    var replyData: Data?
    
    var errorDesc: String?
    
    var date = Date()
    
    var preview: String {
        if let errorDesc = errorDesc {
            return errorDesc
        }
        if reply == nil {
            return inputPreview
        }
        if replyType == .image || replyType == .imageData {
            return String(localized: "[Image]")
        }
        return reply ?? ""
    }
    
    private var inputPreview: String {
        if inputType == .image || inputType == .imageData {
            return String(localized: "[Image]")
        }
        return input
    }
    
    var inputType: MessageType {
        if inputData != nil {
            return .imageData
        }
        if input.hasPrefix("![Image]") {
            return .image
        } else if input.hasPrefix("![ImageData]") {
            return .imageData
        }
        return .text
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
        if let replyData = replyData {
            return replyData
        }
        guard let reply = reply else {
            return nil
        }
        let base64 = String(reply.deletingPrefix("![ImageData](data:image/png;base64,").dropLast())
        return Data(base64Encoded: base64)
    }
}


extension String {
    
    var base64ImageData: Data? {
        guard hasPrefix("![ImageData](data:image/png;base64,") else {
            return nil
        }
        let base64 = String(self.deletingPrefix("![ImageData](data:image/png;base64,").dropLast())
        return Data(base64Encoded: base64)
    }
    
}
