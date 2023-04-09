//
//  HuggingFaceService.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

class HuggingFaceService: @unchecked Sendable {
    
    static let shared = HuggingFaceService()
    
    private lazy var urlSession: URLSession =  {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        let session = URLSession(configuration: configuration)
        return session
    }()
    
    private func makeRequest<T: Codable>(_ api: HuggingFaceAPI, body: T) throws -> URLRequest {
        let url = URL(string: api.baseURL() + api.path)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = api.method
        api.headers.forEach {  urlRequest.setValue($1, forHTTPHeaderField: $0) }
        if let body = body as? Data {
            urlRequest.httpBody = body
        } else {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(body)
        }
        return urlRequest
    }

    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    
    func generateImage(_ input: String) async throws -> String {
        try await generateImage(input, api: .text2Image(
                HuggingFaceModelType(path: HuggingFaceConfiguration.shared.text2ImageModelPath)
            )
        )
    }
    
    func generateImage(_ input: String, api: HuggingFaceAPI) async throws -> String {
        guard !HuggingFaceConfiguration.shared.key.isEmpty else {
            throw String(localized: "HuggingFace User Access Token is not set.")
        }
        
        let request = try makeRequest(api, body: Text2Image(inputs: input))
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw String(localized: "Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = String(localized: "Response Error: \(httpResponse.statusCode)")
            if let errorResponse = try? jsonDecoder.decode(HuggingFaceErrorResponse.self, from: data) {
                error.append("\n\(errorResponse.error)")
            }
            throw error
        }
        
        let base64String = data.base64EncodedString()
        
        if base64String.isEmpty {
            return ""
        } else {
            return "![ImageData](data:image/png;base64,\(base64String))"
        }
    }
    
    func imageClassification(_ image: Data, api: HuggingFaceAPI) async throws -> String {
        guard !HuggingFaceConfiguration.shared.key.isEmpty else {
            throw String(localized: "HuggingFace User Access Token is not set.")
        }
        
        let request = try makeRequest(api, body: image)
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw String(localized: "Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = String(localized: "Response Error: \(httpResponse.statusCode)")
            if let errorResponse = try? jsonDecoder.decode(HuggingFaceErrorResponse.self, from: data) {
                error.append("\n\(errorResponse.error)")
            }
            throw error
        }
        
        let result = try jsonDecoder.decode([ImageClassification].self, from: data)
        return result.reduce("") {
            $0 + "\($1.label): \(Int(100 * $1.score))%\n"
        }
    }
    
    func createCaption(for image: Data) async throws -> String {
        let body = [
            "data" : [
                image.imageBased64String
            ]
        ]
        
        let request = try makeRequest(.imageCaption, body: body)
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw String(localized: "Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = String(localized: "Response Error: \(httpResponse.statusCode)")
            if let errorResponse = try? jsonDecoder.decode(HuggingFaceErrorResponse.self, from: data) {
                error.append("\n\(errorResponse.error)")
            }
            throw error
        }
        
        let result = try jsonDecoder.decode(ImageCaptionResponse.self, from: data)
        if let caption = result.data.first {
            return caption
        } else {
            throw "Invalid Response"
        }
        
    }
    
}

struct ImageCaptionResponse: Codable {
    var data: [String]
    var duration: Double
}

struct HuggingFaceErrorResponse: Codable {
    var error: String
    var estimatedTime: Double
}
