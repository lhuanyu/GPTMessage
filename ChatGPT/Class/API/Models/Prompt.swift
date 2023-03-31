//
//  Prompt.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/21.
//

import Foundation
import SwiftCSV
import SwiftUI

//  {
//    "cmd": "linux_terminal",
//    "act": "Linux Terminal",
//    "prompt": "I want you to act as a linux terminal. I will type commands and you will reply with what the terminal should show. I want you to only reply with the terminal output inside one unique code block, and nothing else. do not write explanations. do not type commands unless I instruct you to do so. when i need to tell you something in english, i will do so by putting text inside curly brackets {like this}. my first command is pwd",
//    "tags": [
//      "chatgpt-prompts"
//    ],
//    "enable": true
//  },

struct Prompt: Codable, Identifiable, Hashable {
    var id: String {
        cmd
    }
    let cmd: String
    let act: String
    let prompt: String
    let tags: [String]
}

class PromptManager: ObservableObject {
    
    static let shared = PromptManager()
    
    private(set) var prompts: [Prompt] = []
    
    init() {
        guard let data = jsonData() else {
            return
        }
        guard let prompts = try? JSONDecoder().decode([Prompt].self, from: data) else {
            return
        }
        self.prompts = prompts.sorted(by: {
            $0.act < $1.act
        })
        print("[Prompt Manager] Load local prompts. Count: \(prompts.count).")
    }
    
    private func jsonData() -> Data? {
        if let data = try? Data(contentsOf: cachedFileURL) {
            print("[Prompt Manager] Load cached prompts.")
            return data
        }
        if let path = Bundle.main.path(forResource: "chatgpt_prompts", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            print("[Prompt Manager] Load bundle prompts.")
            return data
        }
        return nil
    }
    
    @Published private(set) var isSyncing: Bool = false
    
    func sync() {
        guard let url = URL(string: "https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/prompts.csv") else {
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.downloadTask(with: request) { fileURL, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                } else if let fileURL = fileURL {
                    self.parseCSVFile(at: fileURL)
                }
                self.isSyncing = false
            }
        }
        task.resume()
        isSyncing = true
    }
    
    @AppStorage("lastSyncAt") var lastSyncAt: TimeInterval = Date.distantPast.timeIntervalSince1970
    
    private func parseCSVFile(at url: URL) {
        do {
            let csv: CSV = try CSV<Named>(url: url)
            var prompts = [Prompt]()
            try csv.enumerateAsDict({ dic in
                if let act = dic["act"],
                   let prompt = dic["prompt"] {
                    let cmd = act.convertToSnakeCase()
                    prompts.append(.init(cmd: cmd, act: act, prompt: prompt, tags: ["chatgpt-prompts"]))
                }
            })
            self.prompts = prompts.sorted(by: {
                $0.act < $1.act
            })
            print("[Prompt Manager] Sync completed. Count: \(prompts.count).")
            let data = try JSONEncoder().encode(prompts)
            try data.write(to: cachedFileURL, options: .atomic)
            print("[Prompt Manager] Write JSON file to \(cachedFileURL).")
            lastSyncAt = Date().timeIntervalSince1970
        } catch let error as CSVParseError {
            print(error.localizedDescription)
        } catch let error  {
            print(error.localizedDescription)
        }
    }
    
    private var cachedFileURL: URL {
        URL.documentsDirectory.appendingPathComponent("chatgpt_prompts.json")
    }
    
}


extension String {
    
    func convertToSnakeCase() -> String {
        let lowercaseInput = self.lowercased()
        let separatorSet = CharacterSet(charactersIn: "- ")
        let replaced = lowercaseInput
            .replacingOccurrences(of: "`", with: "")
            .components(separatedBy: separatorSet)
            .joined(separator: "_")
        return replaced
    }

}

extension URL {
    
    // Get user's documents directory path
    static func documentDirectoryPath() -> URL {
        let arrayPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = arrayPaths[0]
        return docDirectoryPath
    }
    
}



