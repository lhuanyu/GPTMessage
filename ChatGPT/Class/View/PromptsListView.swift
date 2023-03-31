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
                ForEach(manager.prompts) { prompt in
                    NavigationLink {
                        Form {
                            Section {
                                HStack {
                                    Image(systemName: "terminal.fill")
                                    Text("/\(prompt.cmd)")
                                }
                                
                            }
                            Section("Prompt") {
                                Text(prompt.prompt)
                            }
                        }
                        .navigationTitle(prompt.act)
                    } label: {
                        Text(prompt.act)
                    }

                }
            }
        }
        .navigationTitle("Prompts")
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
