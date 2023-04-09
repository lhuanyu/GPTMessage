//
//  HuggingFace.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

class HuggingFaceConfiguration: ObservableObject {
    
    static let shared = HuggingFaceConfiguration()
    
    @AppStorage("huggingFace.text2ImageModel") var text2ImageModelPath: String = "/stabilityai/stable-diffusion-2-1"
    
    @AppStorage("huggingFace.key") var key: String = ""

}

enum HuggingFaceAPI {

    case text2Image(HuggingFaceModel)
    case imageClassification(HuggingFaceModel)
    case imageCaption
    
    var headers: [String: String] {
        switch self {
        case .imageClassification, .text2Image:
            return  [
                "Authorization": "Bearer \(HuggingFaceConfiguration.shared.key)",
            ]
        case .imageCaption:
            return  [
                "Content-Type" : "application/json"
            ]
        }

    }
    
    var path: String {
        switch self {
        case .text2Image(let huggingFaceModel):
            return huggingFaceModel.path
        case .imageClassification(let huggingFaceModel):
            return huggingFaceModel.path
        case .imageCaption:
            return "/run/predict"
        }
    }
    
    var method: String {
        return "POST"
    }
    
    func baseURL() -> String {
        switch self {
        case .imageClassification, .text2Image:
            return "https://api-inference.huggingface.co/models"
        case .imageCaption:
            return "https://lhuanyu-nlpconnect-vit-gpt2-image-captioning.hf.space"
        }
    }
    
}

protocol HuggingFaceModel {
    
    var owner: String { get }
    var name: String { get }
    var path: String { get }
    
}

extension HuggingFaceModel {
    var path: String {
        "/\(owner)/\(name)"
    }
}

enum CompVis: String, CaseIterable, HuggingFaceModel {
    
    var owner: String { "CompVis" }
    
    var name: String {
        rawValue
    }
    
    case stableDiffusionV14 = "stable-diffusion-v1-4"
}

enum StabilityAI: String, CaseIterable, HuggingFaceModel {
    
    var owner: String { "stabilityai" }
    
    var name: String {
        rawValue
    }
    
    case stableDiffusion2 = "stable-diffusion-2"
    case stableDiffusion21 = "stable-diffusion-2-1"
    case stableDiffusion21Unclip = "stable-diffusion-2-1-unclip"
    case stableDiffusion21UnclipSmall = "stable-diffusion-2-1-unclip-small"
}

enum RunwayML: String, CaseIterable, HuggingFaceModel {
    
    var owner: String { "runwayml" }
    
    var name: String {
        rawValue
    }
    
    case stableDiffusionV15 = "stable-diffusion-v1-5"
}

enum Hakurei: String, CaseIterable, HuggingFaceModel {
    
    var owner: String { "hakurei" }
    
    var name: String { rawValue }
    
    case waifuDiffusion = "waifu-diffusion"
}


struct HuggingFace {
    
    static var text2ImageModels: [HuggingFaceModel] = {
        CompVis.allCases +
        StabilityAI.allCases +
        RunwayML.allCases +
        Hakurei.allCases
    }()
    
}

struct HuggingFaceModelType: HuggingFaceModel {
    
    var owner: String {
        path.dropFirst().components(separatedBy: "/").first ?? ""
    }
    
    var name: String {
        path.components(separatedBy: "/").last ?? ""
    }
    
    var path: String
    
}
