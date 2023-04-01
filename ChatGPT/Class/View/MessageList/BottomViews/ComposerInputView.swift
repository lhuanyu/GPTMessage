//
//  ComposerInputView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/17.
//


import SwiftUI

struct ComposerInputView: View {
    
    @Binding var input: String
    @FocusState var isTextFieldFocused: Bool
    
    var scroll: (() -> Void)?
    var send: (String) -> Void
    
    var size: CGFloat {
#if os(macOS)
        18
#else
        26
#endif
    }
    
    var radius: CGFloat {
#if os(macOS)
        12
#else
        17
#endif
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask anything, or type /", text: $input, axis: .vertical)
                .focused($isTextFieldFocused)
                .multilineTextAlignment(.leading)
                .lineLimit(1...20)
                .padding(.leading, 12)
                .frame(minHeight: size)
                .onTapGesture {
                    scroll?()
                }
#if os(macOS)
                .textFieldStyle(.plain)
#endif
            if !input.isEmpty {
                Button {
                    send(input)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .foregroundColor(.blue)
                        .font(.body.weight(.semibold))
                }
                .keyboardShortcut(.defaultAction)
            } else {
#if os(iOS)
                Button {
                    
                } label: {
                    Image(systemName: "mic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
                .offset(x:-4, y: -4)
#endif
            }
        }
        .macButtonStyle()
        .padding(4)
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(.tertiary, lineWidth: 1)
                .opacity(0.7)
        )
        .padding([.trailing])
    }
}


struct ComposerInputView_Previews: PreviewProvider {
    static var previews: some View {
        ComposerInputView(input: .constant("")) { _ in
            
        }
    }
    
}
