//
//  MacOSSettingsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/3.
//

#if os(macOS)

import SwiftUI

struct MacOSSettingsView: View {
    var body: some View {
        TabView {
            ModelSettingsView()
                .tabItem {
                    Label("Model", systemImage: "brain.head.profile")
                }
            PromptSettingsView()
                .tabItem {
                    Label("Prompt", systemImage: "text.book.closed")
                }
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
        }
        .frame(width: 830, height: 430)
    }
}

struct ModelSettingsView: View {
    
    
    enum Item: String, CaseIterable, Identifiable, Hashable {
        case openAI = "openAI"
        
        var id: String { rawValue }
        
        var destination: some View {
            OpenAISettingsView()
        }
        
        var label: some View {
            HStack {
                Image("openai")
                    .resizable()
                    .frame(width: 40, height: 40)
                Text("OpenAI")
            }
        }
    }
    
    @State var selection: Item? = .openAI
    
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
        }
        .listStyle(.sidebar)
    }
}

struct OpenAISettingsView: View {
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Picker("Model", selection: AppConfiguration.shared.$model) {
                    ForEach(OpenAIModelType.chatModels, id: \.self) { model in
                        Text(model.rawValue)
                            .tag(model)
                    }
                }
                Spacer()
            }
            .padding(.bottom)
            HStack {
                Spacer()
                Slider(value: AppConfiguration.shared.$temperature, in: 0...1) {
                    Text("Temperature")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("1")
                }
                Spacer()
            }
            .padding(.bottom)
            HStack {
                Spacer()
                Image(systemName: "key")
                TextField("", text: AppConfiguration.shared.$key)
                    .truncationMode(.middle)
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}


struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Toggle("Markdown Enabled", isOn: AppConfiguration.shared.$isMarkdownEnabled)
                .padding()
            Spacer()
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
