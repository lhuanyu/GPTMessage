//
//  DialogueSession.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import Foundation
import SwiftUI
import SwiftUIX

class DialogueSession: ObservableObject, Identifiable, Equatable, Hashable, Codable {
    
    struct Configuration: Codable {
        
        var key: String {
            AppConfiguration.shared.key
        }
        
        var model: OpenAIModelType = .chatgpt {
            didSet {
                if !model.supportedModes.contains(mode) {
                    mode = model.supportedModes.first!
                }
            }
        }
        
        var mode: Mode = .chat
        
        var temperature: Double = 0.5
        
        var systemPrompt: String = "You are a helpful assistant"
        
        init() {
            self.model = AppConfiguration.shared.model
            self.temperature = AppConfiguration.shared.temperature
            self.systemPrompt = AppConfiguration.shared.systemPrompt
        }
        
    }
    
    //MARK: - Codable
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configuration = try container.decode(Configuration.self, forKey: .configuration)
        conversations = try container.decode([Conversation].self, forKey: .conversations)
        date = try container.decode(Date.self, forKey: .date)
        id = try container.decode(UUID.self, forKey: .id)
        let messages = try container.decode([Message].self, forKey: .messages)

        isReplying = false
        isStreaming = false
        input = ""
        service = OpenAIService(configuration: configuration)
        service.messages = messages
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configuration, forKey: .configuration)
        try container.encode(conversations, forKey: .conversations)
        try container.encode(service.messages, forKey: .messages)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
    }
    
    enum CodingKeys: CodingKey {
        case configuration
        case conversations
        case messages
        case date
        case id
    }
    
    //MARK: - Hashable, Equatable

    static func == (lhs: DialogueSession, rhs: DialogueSession) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID()
    
    //MARK: - State
    
    @Published var isReplying: Bool = false
    @Published var isSending: Bool = false
    @Published var bubbleText: String = ""
    @Published var isStreaming: Bool = false
    @Published var input: String = ""
    @Published var title: String = "New Chat"
    @Published var conversations: [Conversation] = [] {
        didSet {
            if let date = conversations.last?.date {
                self.date = date
            }
        }
    }
    @Published var date = Date()
    
    
    //MARK: - Properties
    
    @Published var configuration: Configuration = Configuration() {
        didSet {
            service.configuration = configuration
        }
    }
        
    var lastMessage: String {
        if let response = conversations.last?.reply, !response.isEmpty {
            return response
        }
        return conversations.last?.input ?? ""
    }
        
    lazy var service = OpenAIService(configuration: configuration)
    
    init() {
        
    }
    
    //MARK: - Message Actions
    
    @MainActor
    func send(scroll: ((UnitPoint) -> Void)? = nil) async {
        let text = input
        input = ""
        await send(text: text, scroll: scroll)
    }
    
    @MainActor
    func clearMessages() {
        service.removeAllMessages()
        title = "Empty"
        withAnimation { [weak self] in
            self?.conversations = []
        }
    }
    
    @MainActor
    func retry(_ conversation: Conversation, scroll: ((UnitPoint) -> Void)? = nil) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return
        }
        conversations.remove(at: index)
        await send(text: conversation.input, scroll: scroll)
    }
    
    @MainActor
    func edit(_ conversation: Conversation, scroll: ((UnitPoint) -> Void)? = nil) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return
        }
        conversations.remove(at: index)
        await send(text: conversation.input, scroll: scroll)
    }
    
    @MainActor
    private func send(text: String, scroll: ((UnitPoint) -> Void)? = nil) async {
        var streamText = ""
        var conversation = Conversation(
            isReplying: true,
            isLast: true,
            input: text,
            reply: "",
            errorDesc: nil)
        
        if conversations.count > 0 {
            conversations[conversations.endIndex-1].isLast = false
        }
        
        withAnimation {
            scroll?(.bottom)
        }
        
        withAnimation(after: .milliseconds(50)) {
            self.isReplying = true
            self.conversations.append(conversation)
            scroll?(.bottom)
        }
        
        withAnimation(after: .milliseconds(100)) {
            scroll?(.bottom)
        }
        withAnimation(after: .milliseconds(150)) {
            scroll?(.bottom)
        }
        withAnimation(after: .milliseconds(200)) {
            scroll?(.bottom)
        }
        withAnimation(after: .milliseconds(250)) {
            scroll?(.bottom)
        }
        
        
        do {
            let stream = try await service.sendMessageStream(text)
            isStreaming = true
            for try await text in stream {
                streamText += text
                conversation.reply = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                conversations[conversations.count - 1] = conversation
                withAnimation {
                    scroll?(.top)
                    scroll?(.bottom)
                }
            }
            isStreaming = false
        } catch {
            withAnimation {
                conversation.errorDesc = error.localizedDescription
                scroll?(.bottom)
            }
        }
        
        withAnimation {
            conversation.isReplying = false
            conversations[conversations.count - 1] = conversation
            isReplying = false
        }
    }

}
