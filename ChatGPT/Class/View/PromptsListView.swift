//
//  PromptsListView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/31.
//

import SwiftUI

struct PromptsListView: View {
    
    @ObservedObject var manager = PromptManager.shared
            
    var body: some View {
        List {
            if manager.isSyncing {
                Section(header: "", footer: "Updating...") {
                    Button {

                    } label: {
                        HStack {
                            Text("Sync")
                            Spacer()
                            ProgressView()
                        }
                    }
                    .disabled(manager.isSyncing)
                }
            } else {
                Section(header: "", footer: manager.lastSyncAt.dateDesc) {
                    Button {
                        manager.sync()
                    } label: {
                        HStack {
                            Text("Sync")
                        }
                    }
                    .disabled(manager.isSyncing)
                }
            }

            Section {
                ForEach(manager.syncedPrompts) { prompt in
                    NavigationLink {
                        PromptDetailView(prompt: prompt)
                    } label: {
                        Text(prompt.act)
                    }

                }
            }
        }
        .navigationTitle("Prompts")
    }
}

struct PromptDetailView: View {
    
    let prompt: Prompt
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "terminal.fill")
                    Text("/\(prompt.cmd)")
                }
                
            }
            Section("Prompt") {
                Text(prompt.prompt)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle(prompt.act)
    }
    
}

struct PromptsListView_Previews: PreviewProvider {
    static var previews: some View {
        PromptsListView()
    }
}

extension TimeInterval {
    
    var date: Date {
        Date(timeIntervalSince1970: self)
    }
    
    var dateDesc: String {
        if date == .distantPast {
            return "Never"
        }
        return "Last updated on \(date.dateTimeString())"
    }
    
}
