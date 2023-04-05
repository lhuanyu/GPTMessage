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
    
    @AppStorage("configuration.image.size") var imageSize: ImageGeneration.Size = .middle

    
    @AppStorage("configuration.mode") var mode: Mode = .chat
    
    @AppStorage("configuration.isReplySuggestionsEnabled") var isReplySuggestionsEnabled = true
    
    @AppStorage("configuration.isSmartModeEnabled") var isSmartModeEnabled = true
    
    @AppStorage("configuration.temperature") var temperature: Double = 0.5
    
    @AppStorage("configuration.systemPrompt") var systemPrompt: String = "You are a helpful assistant"
    
    @AppStorage("configuration.isMarkdownEnabled") var isMarkdownEnabled: Bool = false
    
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
            Section("Appearance") {
                HStack {
                    Toggle("Markdown Enabled", isOn: $configuration.isMarkdownEnabled)
                    Spacer()
                }
            }
            Section("OpenAI") {
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
                    Stepper(value: $configuration.temperature, in: 0...2, step: 0.1) {
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
                VStack(alignment: .leading) {
                    Toggle("Reply Suggestions", isOn: configuration.$isReplySuggestionsEnabled)
                    Text("ChatGPT will generate reply suggestions based on past conversations.")
                        .foregroundColor(.secondaryLabel)
                }
                VStack(alignment: .leading) {
                    Toggle("Smart Mode", isOn: configuration.$isSmartModeEnabled)
                    Text("ChatGPT will classify your prompt and then select the most appropriate model to handle it.")
                        .foregroundColor(.secondaryLabel)
                }
                HStack {
                    Text("Image Size")
                        .fixedSize()
                    Spacer()
                    Picker("Model", selection: configuration.$imageSize) {
                        ForEach(ImageGeneration.Size.allCases, id: \.self) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
                    .labelsHidden()
                }
                HStack {
                    Image(systemName: "key")
                    Spacer()
                    if showAPIKey {
                        TextField("OpenAI API Key", text: $configuration.key)
                            .truncationMode(.middle)
                    } else {
                        SecureField("OpenAI API Key", text: $configuration.key)
                            .truncationMode(.middle)
                    }
                    Button {
                        showAPIKey.toggle()
                    } label: {
                        if showAPIKey {
                            Image(systemName: "eye.slash")
                        } else {
                            Image(systemName: "eye")
                        }
                    }
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
