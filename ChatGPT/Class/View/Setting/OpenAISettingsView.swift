//
//  OpenAISettingsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/7.
//

import SwiftUI

struct OpenAISettingsView: View {
    
    @StateObject var configuration = AppConfiguration.shared
    
    @State private var showAPIKey = false
    
    var body: some View {
#if os(macOS)
        macOS
#else
        iOS
#endif
    }
    
    var macOS: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Language Model")
                    .bold()
                GroupBox {
                    HStack {
                        Text("Model")
                        Spacer()
                        Picker(selection: configuration.$model) {
                            ForEach(OpenAIModelType.chatModels, id: \.self) { model in
                                Text(model.rawValue)
                                    .tag(model)
                            }
                        }
                        .frame(width: 150)
                    }
                    .padding()
                    Divider()
                    VStack {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Slider(value: configuration.$temperature, in: 0...2) {
                                
                            } minimumValueLabel: {
                                Text("0")
                            } maximumValueLabel: {
                                Text("2")
                            }
                            .width(200)
                            Text(String(format: "%.2f", configuration.temperature))
                                .width(30)
                        }
                    }
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Toggle(isOn: configuration.$isReplySuggestionsEnabled) {
                            HStack {
                                Text("Reply Suggestions")
                                Spacer()
                            }
                        }
                        .toggleStyle(.switch)
                        Text("ChatGPT will generate reply suggestions based on past conversations.")
                            .foregroundColor(.secondaryLabel)
                    }
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Toggle(isOn: configuration.$isSmartModeEnabled) {
                            HStack {
                                Text("Smart Mode")
                                Spacer()
                            }
                        }
                        .toggleStyle(.switch)
                        Text("ChatGPT will classify your prompt and then select the most appropriate model to handle it.")
                            .foregroundColor(.secondaryLabel)
                    }
                    .padding()
                }
                .padding(.bottom)
                Text("DALL·E")
                    .bold()
                GroupBox {
                    HStack {
                        Text("Image Size")
                        Spacer()
                        Picker(selection: configuration.$imageSize) {
                            ForEach(ImageGeneration.Size.allCases, id: \.self) { model in
                                Text(model.rawValue)
                                    .tag(model)
                            }
                        }
                        .frame(width: 100)
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
    
    
    var iOS: some View {
        Form {
            Section {
                HStack {
                    Text("Model")
                        .fixedSize()
                    Spacer()
                    Picker("Model", selection: configuration.$model) {
                        ForEach(OpenAIModelType.chatModels, id: \.self) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
                    .labelsHidden()
                }
                VStack {
                    Stepper(value: $configuration.temperature, in: 0...2, step: 0.1) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", configuration.temperature))
                                .padding(.horizontal)
                                .height(32)
                                .width(60)
                                .background(Color.secondarySystemFill)
                                .cornerRadius(8)
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Toggle("Reply Suggestions", isOn: configuration.$isReplySuggestionsEnabled)
                }
            } header: {
                Text("Language Model")
            } footer: {
                Text("ChatGPT will generate reply suggestions based on past conversations.")
                    .foregroundColor(.secondaryLabel)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Toggle("Smart Mode", isOn: configuration.$isSmartModeEnabled)
                }
            } footer: {
                Text("ChatGPT will classify your prompt and then select the most appropriate model to handle it.")
                    .foregroundColor(.secondaryLabel)
            }
            
            Section("DALL·E") {
                HStack {
                    Text("Image Size")
                        .fixedSize()
                    Spacer()
                    Picker("Model", selection: configuration.$imageSize) {
                        ForEach(ImageGeneration.Size.allCases, id: \.self) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
                    .labelsHidden()
                }
            }
            Section {
                HStack {
                    Image(systemName: "key")
                    Spacer()
                    if showAPIKey {
                        TextField("OpenAI API Key", text: $configuration.key)
                            .truncationMode(.middle)
                    } else {
                        SecureField("OpenAI API Key", text: $configuration.key)
                            .truncationMode(.middle)
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
                }
            }
        }
        .navigationTitle("OpenAI")
    }
}
