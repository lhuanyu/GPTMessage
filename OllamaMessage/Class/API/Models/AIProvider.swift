//
//  AIProvider.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/18.
//

import Foundation
import UIKit

enum OllamaModelProvider: String {
    case qwen
    case deepseek
    case llama
    case mistral
    case phi
    case gemma
    case unknown
    
    var iconURL: URL? {
        switch self {
        case .unknown:
            return nil
        default:
            return URL(string: "https://unpkg.com/@lobehub/icons-static-png@latest/light/\(rawValue)-color.png")
        }
    }
}

extension UIUserInterfaceStyle {
    var styleName: String {
        return self == .dark ? "dark" : "light"
    }
}

extension String {
    var ollamaModelProvider: OllamaModelProvider {
        if self.hasPrefix("qwen") {
            return .qwen
        } else if self.hasPrefix("deepseek") {
            return .deepseek
        } else if self.hasPrefix("llama") {
            return .llama
        } else if self.hasPrefix("mistral") {
            return .mistral
        } else if self.hasPrefix("phi") {
            return .phi
        } else if self.hasPrefix("gemma") {
            return .gemma
        } else {
            return .unknown
        }
    }
}
