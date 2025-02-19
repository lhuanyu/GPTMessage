//
//  OllamaSettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/14.
//

import SwiftUI
import Kingfisher

class OllamaConfiguration: ObservableObject {
    static let shared = OllamaConfiguration()
    
    @AppStorage("ollamaAPIHost") var apiHost: String = ""
    
    @Published var models: [OllamaModel] = []
    @Published var version: String = ""
    
    @MainActor
    func fetchModels() async {
        guard let url = URL(string: apiHost + "/api/tags") else {
            return
        }
        let request = URLRequest(url: url)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let models = try decoder.decode(OllamaModelResponse.self, from: data).models
            self.models = models
            if AppConfiguration.shared.model.isEmpty {
                AppConfiguration.shared.model = models.first?.name ?? ""
            }
            print(models)
        } catch {
            print(error)
        }
    }
}

struct OllamaSettingsView: View {
    @AppStorage("configuration.model") var modelName: String = ""
    
    @AppStorage("ollamaAPIHost") var apiHost: String = ""
    
    @AppStorage("ollamaAPIKey") var apiKey: String = ""
    
    @State var models = [OllamaModel]()
    
    var body: some View {
        List {
            Section("API") {
                TextField("API Key", text: $apiKey)
                TextField("API Host", text: $apiHost)
            }
            Section("Models") {
                if isFetching {
                    HStack {
                        ProgressView()
                    }
                } else {
                    ForEach(models) { model in
                        HStack {
                            KFImage.url(model.name.ollamaModelProvider.iconURL)
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text(model.name + "(\(model.details.parameterSize))")
                            Spacer()
                            if model.name == modelName {
                                Image(systemName: "checkmark")
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            modelName = model.name
                        }
                    }
                }
            }
        }
        .task {
            await fetchModels()
        }
        .onChange(of: apiHost) { _ in
            Task {
                await fetchModels()
            }
        }
        #if os(iOS)
        .navigationBarTitle("Ollama")
        #endif
    }
    
    @State private var isFetching = true
    
    func fetchModels() async {
        guard let url = URL(string: apiHost + "/api/tags") else {
            return
        }
        withAnimation {
            isFetching = true
        }
        let request = URLRequest(url: url)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let models = try decoder.decode(OllamaModelResponse.self, from: data).models
            withAnimation {
                self.models = models
                if modelName.isEmpty {
                    modelName = models.first?.name ?? ""
                }
                isFetching = false
            }
            print(models)
        } catch {
            print(error)
        }
    }
}

#Preview {
    OllamaSettingsView()
}
