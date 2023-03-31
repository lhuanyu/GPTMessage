//
//  DialogueSessionListView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/17.
//

import SwiftUI

struct DialogueSessionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var dialogueSessions: [DialogueSession]
    @Binding var selectedDialogueSession: DialogueSession?
    
    var deleteHandler: (IndexSet) -> Void
    var deleteDialogueHandler: (DialogueSession) -> Void

    var body: some View {
        List(selection: $selectedDialogueSession) {
            ForEach(dialogueSessions) { session in
#if os(iOS)
                HStack {
                    Image("openai")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(20)
                        .padding()
                    VStack(spacing: 4) {
                        NavigationLink(value: session) {
                            HStack {
                                Text(session.configuration.model.rawValue)
                                    .bold()
                                    .font(Font.system(.headline))
                                Spacer()
                                Text(session.date.dialogueDesc)
                                    .font(Font.system(.subheadline))
                                    .foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Text(session.lastMessage)
                                .font(Font.system(.body))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .topLeading
                                )
                        }
                        .frame(height:44)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        deleteDialogueHandler(session)
                        if session == selectedDialogueSession {
                            selectedDialogueSession = nil
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                    }
                }
#else
                NavigationLink(value: session) {
                    HStack {
                        Image("openai")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(20)
                            .padding()
                        VStack(spacing: 4) {
                            HStack {
                                Text(session.configuration.model.rawValue)
                                    .bold()
                                    .font(Font.system(.headline))
                                Spacer()
                                Text(session.date.dialogueDesc)
                                    .font(Font.system(.subheadline))
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text(session.lastMessage)
                                    .font(Font.system(.body))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity,
                                        alignment: .topLeading
                                    )
                            }
                            .frame(height:44)
                        }
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        deleteDialogueHandler(session)
                        if session == selectedDialogueSession {
                            selectedDialogueSession = nil
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                    }
                }
                
#endif
            }
            .onDelete { indexSet in
                deleteHandler(indexSet)
            }
        }
        .onAppear(perform: updateList)
#if os(iOS)
        .listStyle(.plain)
        .navigationTitle(Text("ChatGPT"))
#else
        .frame(minWidth: 300)
        .onChange(of: selectedDialogueSession) { _ in
            if selectedDialogueSession != nil {
                let session = selectedDialogueSession
                updateList()
                selectedDialogueSession = session
            } else {
                updateList()
            }
        }
#endif
        
    }
    
    private func updateList() {
        dialogueSessions = dialogueSessions.sorted(by: {
            $0.date > $1.date
        })
    }
}

extension Date {
    
    var dialogueDesc: String {
        if self.isInYesterday {
            return "Yesterday"
        }
        if self.isInToday {
            return timeString(ofStyle: .short)
        }
        return dateString(ofStyle: .short)
    }
}

import Combine

extension Published.Publisher {
    var didSet: AnyPublisher<Value, Never> {
        // Any better ideas on how to get the didSet semantics?
        // This works, but I'm not sure if it's ideal.
        self.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
}
