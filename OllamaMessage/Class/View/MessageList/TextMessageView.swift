//
//  TextMessageView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct TextMessageView: View {
    
    var think: String?
    var text: String
    var isReplying: Bool
    
    var body: some View {
        if AppConfiguration.shared.isMarkdownEnabled {
            MessageMarkdownView(think: think, text: text)
                .textSelection(.enabled)
        } else {
            if text.isEmpty {
                EmptyView()
            } else {
                Text(text)
                    .textSelection(.enabled)
            }
        }
    }
}

struct TextMessageView_Previews: PreviewProvider {
    static var previews: some View {
        TextMessageView(text: "Test", isReplying: false)
    }
}
