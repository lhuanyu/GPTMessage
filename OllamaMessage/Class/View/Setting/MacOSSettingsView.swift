//
//  MacOSSettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/3.
//

#if os(macOS)

import SwiftUI

struct MacOSSettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            OllamaSettingsView()
                .tabItem {
                    Label("Model", systemImage: "brain.head.profile")
                }
            PromptSettingsView()
                .tabItem {
                    Label("Prompt", systemImage: "text.book.closed")
                }
        }
        .frame(minWidth: 700, minHeight: 400)
    }
}


struct GeneralSettingsView: View {
    
    @StateObject var configuration = AppConfiguration.shared
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Toggle("Markdown Enabled", isOn: configuration.$isMarkdownEnabled)
                    .height(20)
                Spacer()
            }
            .padding(.top)
        }
    }
}


struct PromptSettingsView: View {
    
    enum Item: String, CaseIterable, Identifiable, Hashable {
        case syncPrompts = "syncPrompts"
        case customPrompts = "customPrompts"
        
        var id: String { rawValue }
        
        var destination: some View {
            makeDestination()
        }
        
        @ViewBuilder
        private func makeDestination() -> some View {
            switch self {
            case .syncPrompts:
                PromptsListView()
                    .padding()
            case .customPrompts:
                CustomPromptsView()
            }
        }
        
        var label: some View {
            switch self {
            case .syncPrompts:
                return HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Sync Prompts")
                }
            case .customPrompts:
                return HStack {
                    Image(systemName: "person")
                    Text("Custom Prompts")
                }
            }
        }
    }
    
    @State var selection: Item? = .syncPrompts
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(Item.allCases) { item in
                    NavigationLink(
                        destination: item.destination,
                        tag: item,
                        selection: $selection,
                        label: {
                            item.label
                        }
                    )
                }
            }
            .listStyle(.sidebar)
        }
    }
    
}

struct MacOSSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MacOSSettingsView()
    }
}

#endif


extension String {
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
}
