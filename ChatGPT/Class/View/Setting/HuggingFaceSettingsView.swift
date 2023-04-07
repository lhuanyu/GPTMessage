//
//  HuggingFaceSettingsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct HuggingFaceSettingsView: View {
    
    @ObservedObject var configuration = HuggingFaceConfiguration.shared
    
    @State var showAPIKey = false
        
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
                Text("Text2Image")
                    .bold()
                GroupBox {
                    HStack {
                        Picker("Model", selection: configuration.$text2ImageModelPath) {
                            ForEach(HuggingFace.text2ImageModels, id: \.path) { model in
                                Text(model.path.dropFirst())
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
                    Link("HuggingFace", destination: URL(string: "https://huggingface.co/")!)
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
                    Picker("Model", selection: configuration.$text2ImageModelPath) {
                        ForEach(HuggingFace.text2ImageModels, id: \.path) { model in
                            Text(model.path.dropFirst())
                        }
                    }
                    .labelsHidden()
                }
                HStack {
                    Image(systemName: "key")
                    if showAPIKey  {
                        TextField("", text: configuration.$key)
                            .truncationMode(.middle)
                    } else {
                        SecureField("", text: configuration.$key)
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
            } header: {
                Text("Text2Image")
            }
        }
        .navigationTitle("HuggingFace")
    }
}

struct HuggingFaceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HuggingFaceSettingsView()
    }
}
