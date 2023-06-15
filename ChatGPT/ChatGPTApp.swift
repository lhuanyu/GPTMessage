//
//  ChatGPTApp.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/22.
//

import SwiftUI

@main
struct ChatGPTApp: App {
    
    let persistenceController = PersistenceController.shared
    
    @State var showOpenAIKeyAlert = false
            
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    PromptManager.shared.sync()
                    if AppConfiguration.shared.key.isEmpty {
                        showOpenAIKeyAlert = true
                    }
                }
                .alert("Enter OpenAI API Key", isPresented: $showOpenAIKeyAlert) {
                    TextField("OpenAI API Key", text: AppConfiguration.shared.$key)
                    Button("Later", role: .cancel) { }
                    Button("Confirm", role: .none) { }
                } message: {
                    Text("You need set OpenAI API Key before start a conversation.")
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
#if os(macOS)
        Settings {
            MacOSSettingsView()
        }
#endif
    }
}
