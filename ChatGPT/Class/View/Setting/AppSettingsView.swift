//
//  SettingsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/7.
//

import SwiftUI

class AppConfiguration: ObservableObject {
    
    static let shared = AppConfiguration()
    
    @AppStorage("configuration.key") var key = ""
    
    @AppStorage("configuration.model") var model: OpenAIModelType = .chatgpt {
        didSet {
            if !model.supportedModes.contains(mode) {
                mode = model.supportedModes.first!
            }
        }
    }
    
    @AppStorage("configuration.mode") var mode: Mode = .chat
    
    @AppStorage("configuration.temperature") var temperature: Double = 0.5
    
    @AppStorage("configuration.systemPrompt") var systemPrompt: String = "You are a helpful assistant"
    
    @AppStorage("configuration.isMarkdownEnabled") var isMarkdownEnabled: Bool = false
    
}

extension OpenAIModelType: RawRepresentable {
    var group: OpenAIModelGroup {
        switch self {
        case .textDavinci:
            return .gpt3
        case .textCurie:
            return .gpt3
        case .textBabbage:
            return .gpt3
        case .textAda:
            return .gpt3
        case .codeDavinci:
            return .codex
        case .codeCushman:
            return .codex
        case .textDavinciEdit:
            return .feature
        case .chatgpt:
            return .chat
        case .chatgpt0301:
            return .chat
        }
    }
}

enum OpenAIModelGroup: String, CaseIterable, Codable, Identifiable {
    case chat = "Chat"
    case gpt3 = "GPT3"
    case codex = "Codex"
    case feature = "Feature"
    
    var id: RawValue {
        rawValue
    }
    
    var models: [OpenAIModelType] {
        switch self {
        case .chat:
            return OpenAIModelType.chatModels
        case .gpt3:
            return OpenAIModelType.gpt3Models
        case .codex:
            return OpenAIModelType.codexModels
        case .feature:
            return OpenAIModelType.featureModels
        }
    }
}

struct AppSettingsView: View {
    
    @ObservedObject var configuration: AppConfiguration
    
    @State private var selectedGroup = OpenAIModelGroup.chat
    let groups = [OpenAIModelGroup.chat, .gpt3, .codex]
    
    @State private var selectedModel = OpenAIModelType.chatgpt
    @State var models: [OpenAIModelType] = OpenAIModelType.chatModels
    
    @State private var selectedMode = Mode.chat
    @State var modes = OpenAIModelType.chatgpt.supportedModes
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Appearance") {
                HStack {
                    Toggle("Markdown Enabled", isOn: $configuration.isMarkdownEnabled)
                    Spacer()
                }
            }
            Section("Model") {
                HStack {
                    Text("Model")
                        .fixedSize()
                    Spacer()
                    Picker("Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedModel, perform: updateModes(_:))
                }
                VStack {
                    Stepper(value: $configuration.temperature, in: 0...1, step: 0.1) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", configuration.temperature))
                                .padding(.horizontal)
                                .height(32)
                                .width(60)
                                .background(Color.secondarySystemFill)
                                .cornerRadius(8)
                        }
                    }
                }
                HStack {
                    Image(systemName: "key")
                    Spacer()
                    TextField("OpenAI API Key", text: $configuration.key)
                        .truncationMode(.middle)
                }
            }
            Section("Prompt") {
                NavigationLink {
                    PromptsListView()
                } label: {
                    Text("Sync Prompts")
                }
                NavigationLink {
                    CustomPromptsView()
                } label: {
                    Text("Custom Prompts")
                }
            }
        }
        .onAppear() {
            self.selectedGroup = configuration.model.group
            self.selectedModel = configuration.model
            self.selectedMode = configuration.mode
        }
        .navigationTitle("Settings")
    }
    
    
    private func updateModes(_ model: OpenAIModelType) {
        configuration.model = model
        modes = model.supportedModes
        selectedMode = modes.first!
    }
}


struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AppSettingsView(configuration: AppConfiguration())
        }
    }
}
