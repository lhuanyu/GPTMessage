//
//  SettingsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/7.
//

import SwiftUI


enum AIService: String, CaseIterable {
    case openAI
    case huggingFace
}

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
    
    @AppStorage("configuration.image.size") var imageSize: ImageGeneration.Size = .middle

    
    @AppStorage("configuration.mode") var mode: Mode = .chat
    
    @AppStorage("configuration.isReplySuggestionsEnabled") var isReplySuggestionsEnabled = true
    
    @AppStorage("configuration.isSmartModeEnabled") var isSmartModeEnabled = false
    
    @AppStorage("configuration.temperature") var temperature: Double = 0.8
    
    @AppStorage("configuration.systemPrompt") var systemPrompt: String = "You are a helpful assistant"
    
    @AppStorage("configuration.isMarkdownEnabled") var isMarkdownEnabled: Bool = false
        
    @AppStorage("configuration.preferredText2ImageService") var preferredText2ImageService: AIService = .openAI

}

struct AppSettingsView: View {
    
    @ObservedObject var configuration: AppConfiguration
    
    @State private var selectedModel = OpenAIModelType.chatgpt
    @State var models: [OpenAIModelType] = OpenAIModelType.chatModels
    
    @State private var selectedMode = Mode.chat
    @State var modes = OpenAIModelType.chatgpt.supportedModes
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    @State var showAPIKey = false
    
    var body: some View {
        Form {
            Section("General") {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .renderingMode(.original)
                    Toggle("Markdown Enabled", isOn: $configuration.isMarkdownEnabled)
                    Spacer()
                }
                HStack {
                    Image(systemName: "paintpalette.fill")
                    Text("Text2Image")
                        .fixedSize()
                    Spacer()
                    Picker("Text2Image", selection: configuration.$preferredText2ImageService) {
                        ForEach(AIService.allCases, id: \.self) { service in
                            Text(service.rawValue.capitalizingFirstLetter())
                        }
                    }
                    .labelsHidden()
                }
            }
            Section("Model") {
                NavigationLink {
                    OpenAISettingsView()
                } label: {
                    HStack {
                        Image("openai")
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text("OpenAI")
                    }
                }
                NavigationLink {
                    HuggingFaceSettingsView()
                } label: {
                    HStack {
                        Image("huggingface")
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text("HuggingFace")
                    }
                }
            }
            Section("Prompt") {
                NavigationLink {
                    PromptsListView()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Prompts")
                    }
                }
                NavigationLink {
                    CustomPromptsView()
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Custom Prompts")
                    }
                }
            }
        }
        .onAppear() {
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
