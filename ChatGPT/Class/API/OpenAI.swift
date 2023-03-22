//
//  OpenAI.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/7.
//

import Foundation

/// The type of model used to generate the output
enum OpenAIModelType: String, Codable {
    
    /// A set of models that can understand and generate natural language
    ///
    /// [GPT-3 Models OpenAI API Docs](https://beta.openai.com/docs/models/gpt-3)
    
    /// Most capable GPT-3 model. Can do any task the other models can do, often with higher quality, longer output and better instruction-following. Also supports inserting completions within text.
    ///
    /// > Model Name: text-davinci-003
    case textDavinci = "text-davinci-003"
    
    /// Very capable, but faster and lower cost than GPT3 ``davinci``.
    ///
    /// > Model Name: text-curie-001
    case textCurie = "text-curie-001"
    
    /// Capable of straightforward tasks, very fast, and lower cost.
    ///
    /// > Model Name: text-babbage-001
    case textBabbage = "text-babbage-001"
    
    /// Capable of very simple tasks, usually the fastest model in the GPT-3 series, and lowest cost.
    ///
    /// > Model Name: text-ada-001
    case textAda = "text-ada-001"
    
    static var gpt3Models: [OpenAIModelType] {
        [.textDavinci, .textCurie, .textBabbage, .textAda]
    }
    
    /// A set of models that can understand and generate code, including translating natural language to code
    ///
    /// [Codex Models OpenAI API Docs](https://beta.openai.com/docs/models/codex)
    ///
    ///  >  Limited Beta
    /// Most capable Codex model. Particularly good at translating natural language to code. In addition to completing code, also supports inserting completions within code.
    ///
    /// > Model Name: code-davinci-002
    case codeDavinci = "code-davinci-002"
    
    /// Almost as capable as ``davinci`` Codex, but slightly faster. This speed advantage may make it preferable for real-time applications.
    ///
    /// > Model Name: code-cushman-001
    case codeCushman = "code-cushman-001"
    
    
    static var codexModels: [OpenAIModelType] {
        [.codeDavinci, .codeCushman]
    }
    
    case textDavinciEdit = "text-davinci-edit-001"
    
    
    
    static var featureModels: [OpenAIModelType] {
        [.textDavinciEdit]
    }
    
    /// A set of models for the new chat completions
    ///  You can read the [API Docs](https://platform.openai.com/docs/api-reference/chat/create)
    
    /// Most capable GPT-3.5 model and optimized for chat at 1/10th the cost of text-davinci-003. Will be updated with our latest model iteration.
    /// > Model Name: gpt-3.5-turbo
    case chatgpt = "gpt-3.5-turbo"
    
    /// Snapshot of gpt-3.5-turbo from March 1st 2023. Unlike gpt-3.5-turbo, this model will not receive updates, and will only be supported for a three month period ending on June 1st 2023.
    /// > Model Name: gpt-3.5-turbo-0301
    case chatgpt0301 = "gpt-3.5-turbo-0301"
    
    
    static var chatModels: [OpenAIModelType] {
        [.chatgpt, .chatgpt0301]
    }
    
    var id: RawValue {
        rawValue
    }
    
    var supportedModes: [Mode] {
        switch self {
        case .textDavinci:
            return [.completions]
        case .textCurie:
            return [.completions]
        case .textBabbage:
            return [.completions]
        case .textAda:
            return [.completions]
        case .codeDavinci:
            return [.completions]
        case .codeCushman:
            return [.completions]
        case .textDavinciEdit:
            return [.edits]
        case .chatgpt:
            return [.chat]
        case .chatgpt0301:
            return [.chat]
        }
    }
}

enum Mode: String, CaseIterable, Codable, Identifiable {
    case completions = "Completions"
    case edits = "Edits"
    case chat = "Chat"
    
    var id: RawValue {
        rawValue
    }
}

extension Mode {
    var path: String {
        switch self {
        case .completions:
            return "/v1/completions"
        case .edits:
            return "/v1/edits"
        case .chat:
            return "/v1/chat/completions"
        }
    }
    
    var method: String {
        switch self {
        case .completions, .edits, .chat:
            return "POST"
        }
    }
    
    func baseURL() -> String {
        switch self {
        case .completions, .edits, .chat:
            return "https://api.openai.com"
        }
    }
}
