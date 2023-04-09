//
//  ImageClassification .swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/7.
//

import Foundation

enum Google: String, HuggingFaceModel {
    
    var owner: String {
        "google"
    }
    
    var name: String {
        rawValue
    }
    
    case vitBasePatch16224 = "vit-base-patch16-224"
}

struct ImageClassification: Codable {
    let label: String
    let score: Double
}
