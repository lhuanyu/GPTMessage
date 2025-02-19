//
//  Message.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/15.
//

import Foundation

struct Message: Codable {
    let role: String
    let content: String
    var images: [String]?
}
