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
                    Text("Model")
                        .fixedSize()
                    Spacer()
                    Picker("Model", selection: $configuration.model) {
                        ForEach([OpenAIModelType.chatgpt, .chatgpt0301], id: \.self) { model in
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
            }
        }
        .navigationTitle("Settings")
    }
    
}
