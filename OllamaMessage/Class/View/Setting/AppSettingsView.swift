//
//  SettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/7.
//

import SwiftUI

enum ChatService: String, CaseIterable {
    case ollama
}

class AppConfiguration: ObservableObject {
    
    static let shared = AppConfiguration()
    
    @AppStorage("configuration.key") var key = ""
    
    @AppStorage("configuration.model") var model: String = ""
        
    @AppStorage("configuration.isReplySuggestionsEnabled") var isReplySuggestionsEnabled = true
    
    @AppStorage("configuration.isSmartModeEnabled") var isSmartModeEnabled = false
    
    @AppStorage("configuration.temperature") var temperature: Double = 0.8
    
    @AppStorage("configuration.systemPrompt") var systemPrompt: String = "You are a helpful assistant"
    
    @AppStorage("configuration.isMarkdownEnabled") var isMarkdownEnabled: Bool = true
    
    @AppStorage("configuration.preferredChatService") var preferredChatService: ChatService = .ollama
    
    
    @AppStorage("ollamaAPIHost") var ollamaAPIHost: String = ""

}

struct AppSettingsView: View {
    
    @ObservedObject var configuration: AppConfiguration
    
    @State private var selectedModel = ""
        
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
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Model Provider")
                        .fixedSize()
                    Spacer()
                    Picker("Text2Image", selection: configuration.$preferredChatService) {
                        ForEach(ChatService.allCases, id: \.self) { service in
                            Text(service.rawValue.capitalizingFirstLetter())
                        }
                    }
                    .labelsHidden()
                }
            }
            Section("Model") {
                NavigationLink {
                    OllamaSettingsView()
                } label: {
                    HStack {
                        Image("ollama")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 30, height: 30)
                        Text("Ollama")
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
        }
        .navigationTitle("Settings")
    }
    
    
    private func updateModes(_ model: String) {
        configuration.model = model
        selectedModel = model
    }
}


#Preview {
    NavigationStack {
        AppSettingsView(configuration: AppConfiguration())
    }
}
