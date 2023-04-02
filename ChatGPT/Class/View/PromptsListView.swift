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
            Section(header: "", footer: manager.isSyncing ? "Updating..." : manager.lastSyncAt.dateDesc) {
                HStack {
                    Text("Source")
                    TextField("", text: manager.$promptSource)
                        .truncationMode(.middle)
                        .foregroundColor(Color.secondaryLabel)
                }
                Button {
                    manager.sync()
                } label: {
                    HStack {
                        Text("Sync")
                        if manager.isSyncing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(manager.isSyncing)
            }

            Section {
                ForEach(manager.syncedPrompts.sorted(by: {
                    $0.act < $1.act
                })) { prompt in
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
