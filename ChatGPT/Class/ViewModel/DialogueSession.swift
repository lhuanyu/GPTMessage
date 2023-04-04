//
//  DialogueSession.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import Foundation
import SwiftUI
import SwiftUIX
import AudioToolbox

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
            model = AppConfiguration.shared.model
            temperature = AppConfiguration.shared.temperature
            systemPrompt = AppConfiguration.shared.systemPrompt
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
        initFinished = true
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
    
    var rawData: DialogueData?
    
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
    @Published var suggestions: [String] = []
    @Published var date = Date()
    
    private var initFinished = false
    //MARK: - Properties
    
    @Published var configuration: Configuration = Configuration() {
        didSet {
            service.configuration = configuration
            save()
        }
    }
        
    var lastMessage: String {
        if let response = conversations.last?.replyPreview, !response.isEmpty {
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
            self?.removeAllConversations()
            self?.suggestions.removeAll()
        }
    }
    
    @MainActor
    func retry(_ conversation: Conversation, scroll: ((UnitPoint) -> Void)? = nil) async {
        removeConversation(conversation)
        await send(text: conversation.input, scroll: scroll)
    }
    
    private var lastConversationData: ConversationData?
    
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
            suggestions.removeAll()
            isReplying = true
            lastConversationData = appendConversation(conversation)
            scroll?(.bottom)
        }

        
        AudioServicesPlaySystemSound(1004)
        
        do {
            try await Task.sleep(for: .milliseconds(260))
            withAnimation {
                scroll?(.bottom)
            }
            let stream = try await service.sendMessageStream(text)
            isStreaming = true
            AudioServicesPlaySystemSound(1301)
            for try await text in stream {
                streamText += text
                conversation.reply = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                conversations[conversations.count - 1] = conversation
#if os(iOS)
                withAnimation {
                    scroll?(.top)///for an issue of iOS 16
                    scroll?(.bottom)
                }
#else
                scroll?(.bottom)/// withAnimation may cause scrollview jitter in macOS
#endif
            }
            lastConversationData?.sync(with: conversation)
            isStreaming = false
            createSuggestions(scroll: scroll)
        } catch {
            withAnimation {
                conversation.errorDesc = error.localizedDescription
                lastConversationData?.sync(with: conversation)
                scroll?(.bottom)
            }
        }
        
        withAnimation {
            conversation.isReplying = false
            updateLastConversation(conversation)
            isReplying = false
            scroll?(.bottom)
            save()
        }
    }
    
    func createSuggestions(scroll: ((UnitPoint) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let suggestions = try await service.createSuggestions()
                print(suggestions)
#if os(iOS)
                withAnimation {
                    self.suggestions = suggestions
                    scroll?(.bottom)
                }
#else
                self.suggestions = suggestions
                scroll?(.bottom)
#endif
            } catch let error {
                print(error)
            }
        }
    }

}


extension DialogueSession {
    
    convenience init?(rawData: DialogueData) {
        self.init()
        guard let id = rawData.id,
              let date = rawData.date,
              let configurationData = rawData.configuration,
              let conversations = rawData.conversations as? Set<ConversationData> else {
            return nil
        }
        self.rawData = rawData
        self.id = id
        self.date = date
        if let configuration = try? JSONDecoder().decode(Configuration.self, from: configurationData) {
            self.configuration = configuration
        }
        
        self.conversations = conversations.compactMap { data in
            if let id = data.id,
               let input = data.input,
               let date = data.date {
                let conversation = Conversation(id: id, input: input, reply: data.reply, errorDesc: data.errorDesc, date: date)
                return conversation
            } else {
                return nil
            }
        }
        self.conversations.sort {
            $0.date < $1.date
        }
        
        self.conversations.forEach {
            self.service.appendNewMessage(input: $0.input, reply: $0.reply ?? "")
        }
        if !self.conversations.isEmpty {
            self.conversations[self.conversations.endIndex-1].isLast = true
        }
        initFinished = true
    }
    
    @discardableResult
    func appendConversation(_ conversation: Conversation) -> ConversationData {
        conversations.append(conversation)
        let data = ConversationData(context: PersistenceController.shared.container.viewContext)
        data.id = conversation.id
        data.date = conversation.date
        data.input = conversation.input
        data.reply = conversation.reply
        rawData?.conversations?.adding(data)
        data.dialogue = rawData
        
        do {
            try PersistenceController.shared.save()
        } catch let error {
            print(error.localizedDescription)
        }
        
        return data
    }
    
    func updateLastConversation(_ conversation: Conversation) {
        conversations[conversations.count - 1] = conversation
        lastConversationData?.sync(with: conversation)
    }
    
    func removeConversation(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return
        }
        removeConversation(at: index)
    }
    
    func removeConversation(at index: Int) {
        let isLast = conversations.endIndex-1 == index
        let conversation = conversations.remove(at: index)
        if isLast && !conversations.isEmpty {
            conversations[conversations.endIndex-1].isLast = true
            suggestions.removeAll()
        }
        do {
            if let conversationsSet = rawData?.conversations as? Set<ConversationData>,
               let conversationData = conversationsSet.first(where: {
                $0.id == conversation.id
            }) {
                PersistenceController.shared.container.viewContext.delete(conversationData)
            }
            try PersistenceController.shared.save()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func removeAllConversations() {
        conversations.removeAll()
        do {
            let viewContext = PersistenceController.shared.container.viewContext
            if let conversations = rawData?.conversations as? Set<ConversationData> {
                conversations.forEach(viewContext.delete)
            }
            try PersistenceController.shared.save()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func save() {
        guard initFinished else {
            return
        }
        do {
            rawData?.date = date
            rawData?.configuration = try JSONEncoder().encode(configuration)
            try PersistenceController.shared.save()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
}

extension ConversationData {
    
    func sync(with conversation: Conversation) {
        id = conversation.id
        date = conversation.date
        input = conversation.input
        reply = conversation.reply
        errorDesc = conversation.errorDesc
        do {
            try PersistenceController.shared.save()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}
