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
    
    private func makeRequest(with input: String, mode: Mode? = nil, stream: Bool = false) throws -> URLRequest {
        let mode = mode ?? configuration.mode
        let url = URL(string: mode.baseURL() + mode.path)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = configuration.mode.method
        headers.forEach {  urlRequest.setValue($1, forHTTPHeaderField: $0) }
        urlRequest.httpBody = try makeJSONBody(with: input, mode: mode, stream: stream)
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
    
    private var suggestionsCount: Int {
#if os(iOS)
        return 3
#else
        return 5
#endif
    }
    
    func createSuggestions() async throws -> [String]  {
        var prompt = "Give me \(suggestionsCount) reply suggestions which I may use to ask you based on your last reply. Each suggestion must be in a []. Suggestions must be concise and informative, less than 6 words. If your last reply is in Chinese,your must give me Chinese suggestions. Does not include other words."
        if messages.isEmpty {
            prompt = "Give me \(suggestionsCount) prompts which I can use to chat with you based on your capabilities as an AI language model. Each prompt must be in a []. Prompts should be concise and creative, between 5 and 20 words.  It must not contain these topic: weather, what's you favorite, any other personal questions. Does not include other words."
        }
        
        let suggestionReply = try await sendTaskMessage(prompt)
        print(suggestionReply)

        return suggestionReply.normalizedPrompts
    }
    
    private func makeJSONBody(with input: String, mode: Mode? = nil, stream: Bool = true) throws -> Data {
        let mode = mode ?? configuration.mode
        switch mode {
        case .chat:
            let request = Chat(model: configuration.model.rawValue, temperature: configuration.temperature,
                                  messages: trimConversation(with: input), stream: stream)
            return try JSONEncoder().encode(request)
        case .edits:
            let instruct = Instruction(instruction: input, model: configuration.model.rawValue, input: "")
            return try JSONEncoder().encode(instruct)
        case .completions:
            let command = Command(prompt: input, model: configuration.model.rawValue, maxTokens: 2048 - input.count, temperature: configuration.temperature, stream: stream)
            return try JSONEncoder().encode(command)
        case .image:
            let image = ImageGeneration(prompt: input)
            return try JSONEncoder().encode(image)
        }
    }
    
    func appendNewMessage(input: String, reply: String) {
        messages.append(.init(role: "user", content: input))
        messages.append(.init(role: "assistant", content: reply))
    }
    
    func sendMessageStream(_ input: String) async throws -> AsyncThrowingStream<String, Error> {
        
        if AppConfiguration.shared.isSmartModeEnabled {
            let taskReply = try await sendTaskMessage(
                """
                Determine whether the prompt below is an image generation prompt:
                \(input)
                If it is an image generation prompt, remove the command words in the prompt, leave only the object with modifiers and styles needed to draw, and return it in a [].
                """
            )
            print(taskReply)
            if let prompt = taskReply.normalizedPrompts.first {
                return try await generateImageStream(prompt)
            }
        } else if input.isImageGenerationPrompt {
            return try await generateImageStream(input.imagePrompt)
        }
        
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
                    case .image:
                        fatalError()
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
    
    func sendTaskMessage(_ text: String) async throws -> String {
        let url = URL(string: Mode.chat.baseURL() + Mode.chat.path)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = Mode.chat.method
        headers.forEach {  urlRequest.setValue($1, forHTTPHeaderField: $0) }
        let requestModel = Chat(model: configuration.model.rawValue, temperature: 0,
                              messages: trimConversation(with: text), stream: false)
        urlRequest.httpBody = try JSONEncoder().encode(requestModel)
        
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
            return reply
        } catch {
            throw error
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
    
    func generateImage(_ prompt: String) async throws -> String {
        let urlRequest = try makeRequest(with: prompt, mode: .image)
        
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
            let response = try jsonDecoder.decode(ImageGenerationResponse.self, from: data)
            if let url =  response.data.first?.url {
                return "![Image](\(url.absoluteString))"
            } else {
                throw "Failed to generate image."
            }
        } catch {
            throw error
        }
    }
    
    func generateImageStream(_ prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var image: String
                    switch AppConfiguration.shared.preferredText2ImageService {
                    case .openAI:
                        image = try await generateImage(prompt)
                    case .huggingFace:
                        image = try await HuggingFaceService.shared.generateImage(prompt)
                    }
                    if image.isEmpty {
                        continuation.finish(throwing: "Invalid Response")
                    } else {
                        continuation.yield(image)
                        continuation.finish()
                        self.appendNewMessage(input: prompt, reply: image)
                    }
                } catch {
                    self.appendNewMessage(input: prompt, reply: "")
                    continuation.finish(throwing: error)
                }
            }
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
    
    var isImageGenerationPrompt: Bool {
        lowercased().hasPrefix("draw") || lowercased().hasPrefix("画")
    }
    
    var imagePrompt: String {
        if lowercased().hasPrefix("draw") {
            return self.deletingPrefix("draw")
        } else if hasPrefix("画") {
            return self.deletingPrefix("画")
        }
        return self
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    var normalizedPrompts: [String] {
        var result = [String]()
        let pattern = "\\[(.*?)\\]"

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsText = self as NSString
            let matches = regex.matches(in: self, range: NSRange(location: 0, length: nsText.length))
            
            for match in matches {
                let range = match.range(at: 1)
                let content = nsText.substring(with: range)
                if !result.contains(content) && content.count > 1 {
                    result.append(content)
                }
            }
        } catch {
            print("Error creating regex: \(error.localizedDescription)")
        }
        return result
    }
    
    
}
