//
//  OllamaMessageApp.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/22.
//

import SwiftUI

@main
struct OllamaMessageApp: App {
    
    let persistenceController = PersistenceController.shared
    
    @State var showOllamaHostAlert = false
            
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    if AppConfiguration.shared.ollamaAPIHost.isEmpty {
                        showOllamaHostAlert = true
                    }
                }
                .alert("Enter Ollama API Host", isPresented: $showOllamaHostAlert) {
                    TextField("Ollama API Host", text: AppConfiguration.shared.$ollamaAPIHost)
                    Button("Later", role: .cancel) { }
                    Button("Confirm", role: .none) { }
                } message: {
                    Text("You need set Ollama API host before start a conversation.")
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: AppConfiguration.shared.ollamaAPIHost) { _ in
                    Task {
                        await OllamaConfiguration.shared.fetchModels()
                    }
                }
        }
#if os(macOS)
        Settings {
            MacOSSettingsView()
        }
#endif
    }
}
