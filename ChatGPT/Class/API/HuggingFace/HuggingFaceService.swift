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
        configuration.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: configuration)
        return session
    }()
    
    private func makeRequest<T: Codable>(_ api: HuggingFaceAPI, body: T) throws -> URLRequest {
        let url = URL(string: api.baseURL() + api.path)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = api.method
        api.headers.forEach {  urlRequest.setValue($1, forHTTPHeaderField: $0) }
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(body)
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
            throw "HuggingFace User Access Token is not set."
        }
        
        let request = try makeRequest(api, body: Text2Image(inputs: input))
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = "Response Error: \(httpResponse.statusCode)"
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
    
}

struct HuggingFaceErrorResponse: Codable {
    var error: String
    var estimatedTime: Double
}
