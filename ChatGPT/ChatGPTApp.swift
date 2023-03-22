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

    @StateObject var configuration = AppConfiguration.shared
    @State var dialogueSessions: [DialogueSession] = []
    @State var selectedDialogueSession: DialogueSession?
    
    @State var isShowSettingView = false
    
    @State var showList = false
        
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                contentView()
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button {
                                isShowSettingView = true
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                        ToolbarItem(placement: .automatic) {
                            Button {
                                withAnimation {
                                    dialogueSessions.insert(.init(), at: 0)
                                }
                            } label: {
                                Image(systemName: "square.and.pencil")
                            }
                        }
                    }
            } detail: {
                ZStack {
                    if let selectedDialogueSession = selectedDialogueSession {
                        MessageListView(session:selectedDialogueSession)
                    }
                }
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
#endif
            }
#if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            .background(.secondarySystemBackground)
#endif
            .sheet(isPresented: $isShowSettingView) {
                settingView()
            }
            .onAppear() {
                load()
            }
            .onChange(of: isShowSettingView) { newValue in

            }
            .onChange(of: dialogueSessions.count) { _ in
                save()
            }
            .environment(\.SaveAction, save)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        if dialogueSessions.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "message.fill")
                    .font(.system(size: 50))
                    .padding()
                    .foregroundColor(.secondary)
                Text("No Message")
                    .font(.title3)
                    .bold()
                Spacer()
            }
        } else {
            DialogueSessionListView(
                dialogueSessions: $dialogueSessions,
                selectedDialogueSession: $selectedDialogueSession
            )
        }
    }
    
    @ViewBuilder
    private func settingView() -> some View {
#if os(macOS)
                NavigationStack {
                    AppSettingsView(configuration: configuration)
                        .fixedSize()
                        .padding()
                }
#else
                AppSettingsView(configuration: configuration)
#endif
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: "dialogueSessions"),
              let localDialogueSessions = try? JSONDecoder().decode([DialogueSession].self, from: data) else {
            return
        }
        dialogueSessions = localDialogueSessions
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(dialogueSessions)
            UserDefaults.standard.set(data, forKey: "dialogueSessions")
        } catch {
            print(error)
        }
    }
}

struct SaveActionKey: EnvironmentKey {
    static var defaultValue: (()-> Void)? = nil
}

extension EnvironmentValues {
    var SaveAction:  (()-> Void)? {
        get { self[SaveActionKey.self] }
        set { self[SaveActionKey.self] = newValue }
    }
}
