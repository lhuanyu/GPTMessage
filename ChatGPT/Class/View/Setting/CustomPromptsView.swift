//
//  CustomPromptsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/31.
//

import SwiftUI

struct CustomPromptsView: View {
    
    @State var showAddPromptView = false
    @ObservedObject var manager = PromptManager.shared
    
    @State var name: String = ""
    
    @State var prompt: String = ""
    
    var body: some View {
        contenView()
#if os(iOS)
            .navigationTitle("Custom Prompts")
            .toolbar {
                ToolbarItem {
                    Button {
                        showAddPromptView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
#endif
            .sheet(isPresented: $showAddPromptView) {
#if os(iOS)
                NavigationStack {
                    editingPromptView
                        .navigationTitle("Add Prompt")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem {
                                Button {
                                    showAddPromptView = false
                                } label: {
                                    Text("Cancel")
                                }
                            }
                        }
                }
#else
                editingPromptView
#endif
            }
    }
    
    @ViewBuilder
    func contenView() -> some View {
#if os(iOS)
        if manager.customPrompts.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "tray")
                    .font(.system(size: 50))
                    .padding()
                    .foregroundColor(.secondary)
                Text("No Prompts")
                    .font(.title3)
                    .bold()
                Spacer()
            }
        } else {
            List {
                ForEach(manager.customPrompts) { prompt in
                    NavigationLink {
                        PromptDetailView(prompt: prompt)
                    } label: {
                        Text(prompt.act)
                    }
                }
                .onDelete { indexSet in
                    withAnimation {
                        manager.removeCustomPrompts(atOffsets: indexSet)
                    }
                }
            }
        }
#else
        VStack(alignment: .leading) {
            Button {
                showAddPromptView = true
            } label: {
                Text("Add Prompt")
            }
            List {
                Section {
                    ForEach(manager.customPrompts) { prompt in
                        VStack {
                            HStack {
                                Text(prompt.act)
                                Spacer()
                                Button {
                                    manager.removeCustomPrompt(prompt)
                                } label: {
                                    Image(systemName: "trash.circle")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    if selectedPrompt == prompt {
                                        selectedPrompt = nil
                                    } else {
                                        selectedPrompt = prompt
                                    }
                                } label: {
                                    if selectedPrompt == prompt {
                                        Image(systemName: "arrowtriangle.up.circle")
                                    } else {
                                        Image(systemName: "info.circle")
                                    }
                                }
                                .buttonStyle(.borderless)
                            }
                            if selectedPrompt == prompt {
                                PromptDetailView(prompt: prompt)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.systemBackground)
                            }
                        }
                    }
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: false))
        }
        .padding()
#endif
    }
    
    @State var selectedPrompt: Prompt?
    
    var editingPromptView: some View {
        #if os(iOS)
        Form {
            Section {
                HStack {
                    Text("Name")
                        .bold()
                    Spacer()
                    TextField("Type a shortcut name", text: $name)
                }
                HStack(alignment: .top) {
                    Text("Prompt")
                        .bold()
                    Spacer()
                    TextField("Type a prompt", text: $prompt, axis: .vertical)
                        .lineLimit(1...30)
                }
            }
            Section {
                Button {
                    showAddPromptView = false
                    addPrompt()
                } label: {
                    HStack {
                        Spacer()
                        Text("Confirm")
                        Spacer()
                    }
                }
                .disabled(name.isEmpty || prompt.isEmpty)
            }
        }
        #else
        VStack {
            HStack {
                HStack {
                    Spacer()
                    Text("Name:")
                }
                .width(60)
                Spacer()
                TextField("Type a shortcut name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Prompt:")
                }
                .width(60)
                Spacer()
                TextEditor(text: $prompt)
                    .border(Color.gray.opacity(0.1), width: 1)
            }
            Spacer()
            Button {
                showAddPromptView = false
                addPrompt()
            } label: {
                HStack {
                    Spacer()
                    Text("Confirm")
                    Spacer()
                }
            }
            .disabled(name.isEmpty || prompt.isEmpty)
            Button(role: .cancel) {
                showAddPromptView = false
            } label: {
                HStack {
                    Spacer()
                    Text("Cancel")
                    Spacer()
                }
            }
        }
        .minHeight(300)
        .minWidth(400)
        .padding()
        #endif

    }
    
    
    func addPrompt() {
        guard !name.isEmpty && !prompt.isEmpty else {
            return
        }
        withAnimation {
            manager.addCustomPrompt(.init(cmd: name.convertToSnakeCase(), act: name, prompt: prompt, tags: []))
        }
    }
    
}

struct CustomPromptsView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPromptsView()
    }
}
