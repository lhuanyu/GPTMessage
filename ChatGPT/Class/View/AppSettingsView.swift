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
            Section(header: "Display") {
                HStack {
                    Toggle("Markdown Enabled", isOn: $configuration.isMarkdownEnabled)
                    Spacer()
                }
            }
            Section(header: "Model") {
                HStack {
#if os(iOS)
                    Text("Model")
                        .fixedSize()
                    Spacer()
#endif
                    Picker("Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
#if os(iOS)
                    .labelsHidden()
#endif
                    .onChange(of: selectedModel, perform: updateModes(_:))
                }
                VStack {
#if os(iOS)
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
#else
                    Slider(value: $configuration.temperature) {
                        Text("Temperature")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("1")
                    }
#endif
                }
                HStack {
                    Image(systemName: "key")
                    Spacer()
                    TextField("", text: $configuration.key)
                }
            }
            
#if os(iOS)
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
#else
            Section {
                Button {
                    PromptManager.shared.sync()
                } label: {
                    Text("Sync Prompts")
                }
                .padding(.top)
                .disabled(PromptManager.shared.isSyncing)
            } footer: {
                Text(PromptManager.shared.lastSyncAt.dateDesc)
            }
#endif
        }
        .onAppear() {
            self.selectedGroup = configuration.model.group
            self.selectedModel = configuration.model
            self.selectedMode = configuration.mode
        }
        .navigationTitle("Settings")
#if os(macOS)
        .frame(width: 400)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
#endif
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
