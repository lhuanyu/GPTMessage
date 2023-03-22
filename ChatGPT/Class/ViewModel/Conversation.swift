//
//  Conversation.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

struct Conversation: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var isReplying: Bool
    
    var isLast: Bool
    
    var input: String
    
    var reply: String?
    
    var errorDesc: String?
    
    var date = Date()
    
}
