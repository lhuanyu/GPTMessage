//
//  TextMessageView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct TextMessageView: View {
    
    var text: String
    var isReplying: Bool
    
    var body: some View {
        if text.isEmpty {
            EmptyView()
        } else {
            if AppConfiguration.shared.isMarkdownEnabled && !isReplying {
                MessageMarkdownView(text: text)
                    .textSelection(.enabled)
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
