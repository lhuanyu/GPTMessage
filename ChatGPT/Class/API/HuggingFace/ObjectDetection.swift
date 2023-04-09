//
//  ObjectDetection.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/8.
//

import Foundation

enum Facebook: String, HuggingFaceModel {
    
    var owner: String {
        "facebook"
    }
    
    var name: String {
        rawValue
    }
    
    case detrResnet50 = "detr-resnet-50"
}

struct ObjectDetection: Codable {
    let label: String
    let score: Double
    let box: Box
}

struct Box: Codable {
    let xmin: CGFloat
    let xmax: CGFloat
    let ymin: CGFloat
    let ymax: CGFloat
}
