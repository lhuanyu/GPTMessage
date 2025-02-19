//
//  OllamaService.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/15.
//

import SwiftUI

class OllamaService: @unchecked Sendable {
    init(configuration: DialogueSession.Configuration) {
        self.configuration = configuration
    }
    
    var configuration: DialogueSession.Configuration
        
    var messages = [Message]()
    
    func createTitle() async throws -> String {
        let prompt = "Generate a title based on the conversation, it should be a short sentence, return the title only."
        return try await chat(prompt)
    }
        
    private var suggestionsCount: Int {
#if os(iOS)
        return 3
#else
        return 5
#endif
    }
    
    func createSuggestions() async throws -> [String] {
        let chatHistory = messages.reduce("") { $0 + "[\($1.role)]\($1.content)" + "\n" }
        let prompt = """
        Generate \(suggestionsCount) suggestions for user input based on the conversation below: \n\(chatHistory)\n The suggestions should use the same language as the main language of the conversation. The suggestions should be short and unique. Return the suggestions only in an array format, such as: ["suggestion1", "suggestion2", "suggestion3"], do not use markdown syntax. You must return \(suggestionsCount) suggestions.
        """
        let suggestions = try await chat(prompt, model: "qwen2:latest", includingHistory: false)
        print("Suggestions: \(suggestions)")
        return suggestions.normalizedPrompts
    }
    
    func appendNewMessage(input: String, reply: String) {
        messages.append(.init(role: "user", content: input))
        messages.append(.init(role: "assistant", content: reply))
    }
    
    func sendMessage(_ input: String, data: Data? = nil) async throws -> AsyncThrowingStream<String, Error> {
        do {
            return try await chatStream(input, data: data)
        } catch {
            appendNewMessage(input: input, reply: "")
            throw error
        }
    }
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func chatStream(_ input: String, data: Data? = nil) async throws -> AsyncThrowingStream<String, Error> {
        do {
            
            let chatRequest = OllamaChatRequest(
                model: configuration.model,
                messages: messages + [
                    Message(
                        role: "user",
                        content: input,
                        images: data != nil ? [data!.base64EncodedString()] : nil
                    )
                ]
            )
            
            guard let url = URL(string: AppConfiguration.shared.ollamaAPIHost + "/api/chat") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(chatRequest)
            request.timeoutInterval = 60 * 5
            
            let (bytes, _) = try await URLSession.shared.bytes(for: request)
            
            var responseContent = ""

            return AsyncThrowingStream<String, Error> { continuation in
                Task(priority: .userInitiated) {
                    do {
                        for try await line in bytes.lines {
                            responseContent += line
                            print("Received chunk: \(line)")
                            if let response = try? decoder.decode(OllamaResponse.self, from: Data(line.utf8)) {
                                continuation.yield(response.message.content)
                            } else if let finalResponse = try? decoder.decode(OllamaFinalResponse.self, from: Data(line.utf8)) {
                                print("Final response: \(finalResponse)")
                            } else {
                                continuation.finish(throwing: URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: line]))
                            }
                        }
                        appendNewMessage(input: input, reply: responseContent)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    /// no stream
    func chat(_ input: String, model: String? = nil, messages: [Message] = [], includingHistory: Bool = false) async throws -> String {
        do {
            let chatRequest = OllamaChatRequest(
                model: model ?? configuration.model,
                messages: includingHistory ? messages + [Message(role: "user", content: input)] : [Message(role: "user", content: input)],
                stream: false
            )
            
            guard let url = URL(string: AppConfiguration.shared.ollamaAPIHost + "/api/chat") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(chatRequest)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try decoder.decode(OllamaResponse.self, from: data)
            return response.message.content
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    func removeAllMessages() {
        messages.removeAll()
    }
}

extension String {
    var isImageGenerationPrompt: Bool {
        lowercased().hasPrefix("draw") || lowercased().hasPrefix("画")
    }
    
    var imagePrompt: String {
        if lowercased().hasPrefix("draw") {
            return deletingPrefix("draw")
        } else if hasPrefix("画") {
            return deletingPrefix("画")
        }
        return self
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    
    var normalizedPrompts: [String] {
        /// Use regex to extract suggestions from the ["Compare the prices", "Analyze the market trends", "Suggest budget alternatives"]
        let pattern = #""([^"]*)""#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        var result = [String]()
        for match in matches {
            if let range = Range(match.range(at: 1), in: self) {
                result.append(String(self[range]))
            }
        }
        return result
    }
}
