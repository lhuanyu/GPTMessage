//
//  Prompt.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/21.
//

import Foundation

//  {
//    "cmd": "linux_terminal",
//    "act": "Linux Terminal",
//    "prompt": "I want you to act as a linux terminal. I will type commands and you will reply with what the terminal should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is pwd",
//    "tags": [
//      "chatgpt-prompts"
//    ],
//    "enable": true
//  },

struct Prompt: Codable, Identifiable {
    var id: String {
        cmd
    }
    let cmd: String
    let act: String
    let prompt: String
    let tags: [String]
}

struct PromptManager {
    
    static let shared = PromptManager()
    
    var prompts: [Prompt] = []
    
    init() {
        guard let path = Bundle.main.path(forResource: "chatgpt_prompts", ofType: "json") else {
            return
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return
        }
        guard let prompts = try? JSONDecoder().decode([Prompt].self, from: data) else {
            return
        }
        self.prompts = prompts
    }
    
}
