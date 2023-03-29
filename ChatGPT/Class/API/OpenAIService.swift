//
//  OpenAIService.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

class OpenAIService: @unchecked Sendable {
    
    init(configuration: DialogueSession.Configuration) {
        self.configuration = configuration
    }
    
    var configuration: DialogueSession.Configuration
    
    var messages = [Message]()
    private var trimmedMessagesIndex = 0
    
    private lazy var urlSession: URLSession =  {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: configuration)
        return session
    }()
    
    private func makeRequest(with input: String, stream: Bool = false) throws -> URLRequest {
        let url = URL(string: configuration.mode.baseURL() + configuration.mode.path)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = configuration.mode.method
        headers.forEach {  urlRequest.setValue($1, forHTTPHeaderField: $0) }
        urlRequest.httpBody = try makeJSONBody(with: input, stream: stream)
        return urlRequest
    }

    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(configuration.key)"
        ]
    }
    
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    
    private func trimConversation(with input: String) -> [Message] {
        var trimmedMessages = [Message]()
        if trimmedMessagesIndex > messages.endIndex - 1 {
            trimmedMessages.append(Message(role: "user", content: input))
        } else {
            trimmedMessages += messages[trimmedMessagesIndex...]
            trimmedMessages.append(Message(role: "user", content: input))
        }
        
        let maxToken = 4096
        print("maxToken:\(maxToken)")
        var tokenCount = trimmedMessages.tokenCount
        print("tokenCount:\(tokenCount)")
        while tokenCount > maxToken {
            print(trimmedMessages.remove(at: 0))
            trimmedMessagesIndex += 1
            print("trimmedMessagesIndex: \(trimmedMessagesIndex)")
            tokenCount = trimmedMessages.tokenCount
            print("tokenCount:\(tokenCount)")
        }
        
        trimmedMessages.insert(Message(role: "system", content: configuration.systemPrompt), at: 0)
        
        return trimmedMessages
    }
    
    func createTitle() async throws -> String {
        try await sendMessage("Summarize our conversation, give me a title as short as possible in the language of your last response. Return the title only.", appendNewMessage: false)
    }
    
    private func makeJSONBody(with input: String, stream: Bool = true) throws -> Data {
        switch configuration.mode {
        case .chat:
            let request = Request(model: configuration.model.rawValue, temperature: configuration.temperature,
                                  messages: trimConversation(with: input), stream: stream)
            return try JSONEncoder().encode(request)
        case .edits:
            let instruct = Instruction(instruction: input, model: configuration.model.rawValue, input: "")
            return try JSONEncoder().encode(instruct)
        case .completions:
            let command = Command(prompt: input, model: configuration.model.rawValue, maxTokens: 2048 - input.count, temperature: configuration.temperature, stream: stream)
            return try JSONEncoder().encode(command)
        }
    }
    
    func appendNewMessage(input: String, reply: String) {
        messages.append(.init(role: "user", content: input))
        messages.append(.init(role: "assistant", content: reply))
    }
    
    func sendMessageStream(_ input: String) async throws -> AsyncThrowingStream<String, Error> {
        let urlRequest = try makeRequest(with: input, stream: true)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var errorText = ""
            for try await line in result.lines {
                errorText += line
            }
            
            if let data = errorText.data(using: .utf8), let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                errorText = "\n\(errorResponse.message)"
            }
            
            throw "Response Error: \(httpResponse.statusCode), \(errorText)"
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                do {
                    var reply = ""
                    
                    switch self.configuration.mode {
                    case .completions, .edits:
                        for try await line in result.lines {
                            if line.hasPrefix("data: "),
                               let data = line.dropFirst(6).data(using: .utf8),
                               let response = try? self.jsonDecoder.decode(StreamResponse<TextChoice>.self, from: data),
                               let text = response.choices.first?.text {
                                reply += text
                                continuation.yield(text)
                            }
                        }
                    case .chat:
                        for try await line in result.lines {
                            if line.hasPrefix("data: "),
                               let data = line.dropFirst(6).data(using: .utf8),
                               let response = try? self.jsonDecoder.decode(StreamCompletionResponse.self, from: data),
                               let text = response.choices.first?.delta.content {
                                reply += text
                                continuation.yield(text)
                            }
                        }
                    }
                    self.appendNewMessage(input: input, reply: reply)
                    continuation.finish()
                } catch {
                    self.appendNewMessage(input: input, reply: "")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func sendMessage(_ text: String, appendNewMessage: Bool = true) async throws -> String {
        let urlRequest = try makeRequest(with: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = "Response Error: \(httpResponse.statusCode)"
            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                error.append("\n\(errorResponse.message)")
            }
            throw error
        }
        
        do {
            let completionResponse = try jsonDecoder.decode(CompletionResponse.self, from: data)
            let reply = completionResponse.choices.first?.message.content ?? ""
            if appendNewMessage {
                self.appendNewMessage(input: text, reply: reply)
            }
            return reply
        } catch {
            if appendNewMessage {
                self.appendNewMessage(input: text, reply: "")
            }
            throw error
        }
    }
    
    func removeAllMessages() {
        messages.removeAll()
    }
}

extension String: CustomNSError {
    
    public var errorUserInfo: [String : Any] {
        [
            NSLocalizedDescriptionKey: self
        ]
    }
}


