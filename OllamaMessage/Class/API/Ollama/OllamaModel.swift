//
//  OllamaModel.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/14.
//

import Foundation

//{
//  "models": [
//    {
//      "name": "codellama:13b",
//      "modified_at": "2023-11-04T14:56:49.277302595-07:00",
//      "size": 7365960935,
//      "digest": "9f438cb9cd581fc025612d27f7c1a6669ff83a8bb0ed86c94fcf4c5440555697",
//      "details": {
//        "format": "gguf",
//        "family": "llama",
//        "families": null,
//        "parameter_size": "13B",
//        "quantization_level": "Q4_0"
//      }
//    },
//    {
//      "name": "llama3:latest",
//      "modified_at": "2023-12-07T09:32:18.757212583-08:00",
//      "size": 3825819519,
//      "digest": "fe938a131f40e6f6d40083c9f0f430a515233eb2edaa6d72eb85c50d64f2300e",
//      "details": {
//        "format": "gguf",
//        "family": "llama",
//        "families": null,
//        "parameter_size": "7B",
//        "quantization_level": "Q4_0"
//      }
//    }
//  ]
//}

struct OllamaModelResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable, Identifiable {
    
    struct Details: Codable {
        let format: String
        let family: String
        let families: [String]?
        let parameterSize: String
        let quantizationLevel: String
    }
    
    var id: String { name }
    
    
    let name: String
    let modifiedAt: String
    let size: Int
    let digest: String
    let details: Details
    
}
// 请求体模型
struct OllamaChatRequest: Codable {
    let model: String
    let messages: [Message]
    var stream: Bool?
}

// Chat response
//{
//  "model": "llama3.2",
//  "created_at": "2023-08-04T08:52:19.385406455-07:00",
//  "message": {
//    "role": "assistant",
//    "content": "The",
//    "images": null
//  },
//  "done": false
//}

struct OllamaResponse: Codable {
    let model: String
    let createdAt: String
    let message: Message
    let done: Bool
}

//Chat Final Response
//{
//  "model": "llama3.2",
//  "created_at": "2023-08-04T19:22:45.499127Z",
//  "done": true,
//  "total_duration": 4883583458,
//  "load_duration": 1334875,
//  "prompt_eval_count": 26,
//  "prompt_eval_duration": 342546000,
//  "eval_count": 282,
//  "eval_duration": 4535599000
//}

struct OllamaFinalResponse: Codable {
    let model: String
    let createdAt: String
    let done: Bool
    let totalDuration: Int
    let loadDuration: Int
    let promptEvalCount: Int
    let promptEvalDuration: Int
    let evalCount: Int
    let evalDuration: Int
}

