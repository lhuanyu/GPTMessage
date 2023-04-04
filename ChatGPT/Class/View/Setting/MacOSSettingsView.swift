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
        .frame(minWidth: 700, minHeight: 400)
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
            .listStyle(.sidebar)
        }
    }
}

struct OpenAISettingsView: View {
    
    @StateObject var configuration = AppConfiguration.shared
    
    @State private var showAPIKey = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Language Model")
                    .bold()
                GroupBox {
                    HStack {
                        Picker("Model", selection: configuration.$model) {
                            ForEach(OpenAIModelType.chatModels, id: \.self) { model in
                                Text(model.rawValue)
                                    .tag(model)
                            }
                        }
                    }
                    .padding()
                    Divider()
                    VStack {
                        HStack {
                            Slider(value: configuration.$temperature, in: 0...2) {
                                Text("Temperature")
                            } minimumValueLabel: {
                                Text("0")
                            } maximumValueLabel: {
                                Text("1")
                            }
                            Text(String(format: "%.2f", configuration.temperature))
                                .width(30)
                        }
                    }
                    .padding()
                }
                .padding(.bottom)
                Text("DALL·E")
                    .bold()
                GroupBox {
                    HStack {
                        Picker("Image Size", selection: configuration.$imageSize) {
                            ForEach(ImageGeneration.Size.allCases, id: \.self) { model in
                                Text(model.rawValue)
                                    .tag(model)
                            }
                        }
                    }
                    .padding()
                }
                .padding(.bottom)
                GroupBox {
                    HStack {
                        Image(systemName: "key")
                        if showAPIKey  {
                            TextField("", text: configuration.$key)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("", text: configuration.$key)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            if showAPIKey {
                                Image(systemName: "eye.slash")
                            } else {
                                Image(systemName: "eye")
                            }
                        }
                        .buttonStyle(.borderless)

                    }
                    .padding()
                }
                HStack {
                    Spacer()
                    Link("OpenAI Documentation", destination: URL(string: "https://platform.openai.com/docs/introduction")!)
                }
                Spacer()
            }
            .padding()
        }
    }
}


struct AppearanceSettingsView: View {
    
    @StateObject var configuration = AppConfiguration.shared
    
    var body: some View {
        Form {
            Toggle("Markdown Enabled", isOn: configuration.$isMarkdownEnabled)
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
