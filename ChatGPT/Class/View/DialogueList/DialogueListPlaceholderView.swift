//
//  DialogueListPlaceholderView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/29.
//

import SwiftUI

struct DialogueListPlaceholderView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "message.fill")
                .font(.system(size: 50))
                .padding()
                .foregroundColor(.secondary)
            Text("No Message")
                .font(.title3)
                .bold()
            Spacer()
        }
    }
}

struct DialogueListPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        DialogueListPlaceholderView()
    }
}
