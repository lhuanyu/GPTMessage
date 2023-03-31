//
//  ContentView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DialogueData.date, ascending: false)],
        animation: .default)
    private var items: FetchedResults<DialogueData>
    
    @StateObject var configuration = AppConfiguration.shared
    @State var dialogueSessions: [DialogueSession] = []
    @State var selectedDialogueSession: DialogueSession?
    
    @State var isShowSettingView = false

    var body: some View {
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
                            addItem()
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
#else
            .frame(minWidth: 500)
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
            dialogueSessions = items.compactMap {
                DialogueSession(rawData: $0)
            }
        }


    }
    
    
    @ViewBuilder
    func contentView() -> some View {
        if dialogueSessions.isEmpty {
            DialogueListPlaceholderView()
        } else {
            DialogueSessionListView(
                dialogueSessions: $dialogueSessions,
                selectedDialogueSession: $selectedDialogueSession) {
                    deleteItems(offsets: $0)
                } deleteDialogueHandler: {
                    deleteItem($0)
                }
        }
    }
    
    @ViewBuilder
    private func settingView() -> some View {
#if os(macOS)
        AppSettingsView(configuration: configuration)
            .padding()
            .fixedSize()
#else
        NavigationStack {
            AppSettingsView(configuration: configuration)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Button {
                            isShowSettingView = false
                        } label: {
                            Text("Done")
                                .bold()
                        }
                    }
                }
        }
#endif
    }


    private func addItem() {
        withAnimation {
            do {
                let session = DialogueSession()
                dialogueSessions.insert(session, at: 0)
                let newItem = DialogueData(context: viewContext)
                newItem.id = session.id
                newItem.date = session.date
                newItem.configuration =  try JSONEncoder().encode(session.configuration)
                try PersistenceController.shared.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            dialogueSessions.remove(atOffsets: offsets)
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try PersistenceController.shared.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItem(_ session: DialogueSession) {
        withAnimation {
            dialogueSessions.removeAll {
                $0.id == session.id
            }
            if let item = session.rawData {
                viewContext.delete(item)
            }

            do {
                try PersistenceController.shared.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
}
