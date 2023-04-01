//
//  DialogueSettingsView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/26.
//

import SwiftUI

struct DialogueSettingsView: View {
    
    @Binding var configuration: DialogueSession.Configuration
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                HStack {
#if os(iOS)
                    Text("Model")
                        .fixedSize()
                    Spacer()
#endif
                    Picker("Model", selection: $configuration.model) {
                        ForEach([OpenAIModelType.chatgpt, .chatgpt0301], id: \.self) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
#if os(iOS)
                    .labelsHidden()
#endif
                }
                VStack {
#if os(iOS)
                    Stepper(value: $configuration.temperature, in: 0...1, step: 0.1) {
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
#else
                    Text(String(format: "%.2f", configuration.temperature))
                        .foregroundColor(.blue)
                    Slider(value: $configuration.temperature) {
                        Text("Temperature")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("1")
                    }
#endif
                }
            }
        }
        .navigationTitle("Settings")
#if os(macOS)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Close") {
                    dismiss()
                }
            }
        }
#endif
    }
    
}
