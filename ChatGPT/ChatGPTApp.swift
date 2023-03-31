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
            
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    PromptManager.shared.sync()
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
