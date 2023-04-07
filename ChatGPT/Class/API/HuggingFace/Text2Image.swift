//
//  Text2Image.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import Foundation

struct Text2Image: Codable {
    var inputs: String
    var options: HuggingFaceOptions = .init()
}

struct HuggingFaceOptions: Codable {
    var waitForModel = true ///usually cost 20 seconds or longer
}
