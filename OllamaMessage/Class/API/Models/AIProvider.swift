//
//  AIProvider.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/18.
//

import Foundation

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
        case .llama:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/light/ollama.png")
        default:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/light/\(rawValue)-color.png")
        }
    }
}

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit

extension UIUserInterfaceStyle {
    var styleName: String {
        return self == .dark ? "dark" : "light"
    }
}
#endif

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
