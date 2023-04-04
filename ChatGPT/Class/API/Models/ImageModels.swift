//
//  ImageModels.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/4.
//

import Foundation



struct ImageGeneration: Codable {
    enum Size: String, Codable, CaseIterable {
        case small = "256x256"
        case middle = "512x512"
        case large = "1024x1024"
    }
    
    var prompt: String
    var n: Int = 1
    var size: Size = AppConfiguration.shared.imageSize
}

//{
//  "created": 1589478378,
//  "data": [
//    {
//      "url": "https://..."
//    },
//    {
//      "url": "https://..."
//    }
//  ]
//}
struct ImageGenerationResponse: Codable {
    var data: [URLResponse]
}

struct URLResponse: Codable {
    var url: URL
}
