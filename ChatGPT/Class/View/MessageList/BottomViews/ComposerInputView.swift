//
//  ComposerInputView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/17.
//


import SwiftUI

struct ComposerInputView: View {
    
    @ObservedObject var session: DialogueSession
    @FocusState var isTextFieldFocused: Bool
    let namespace: Namespace.ID
    
    var send: (String) -> Void
    
    private var size: CGFloat {
#if os(macOS)
        24
#else
        26
#endif
    }
    
    var radius: CGFloat {
#if os(macOS)
        16
#else
        17
#endif
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            textField
            if let data = session.sendingData {
                animationImageView(data)
            } else if let data = session.inputData {
                imageView(data)
            } else if session.isSending {
                animationTextView
            }
            sendButton
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
    
    @ViewBuilder
    private var textField: some View {
        if session.inputData == nil {
            TextField("Ask anything, or type /", text: $session.input, axis: .vertical)
                .focused($isTextFieldFocused)
                .multilineTextAlignment(.leading)
                .lineLimit(1...20)
                .padding(.leading, 12)
                .padding(.trailing, size + 6)
                .frame(minHeight: size)
    #if os(macOS)
                .textFieldStyle(.plain)
    #endif
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func animationImageView(_ data: Data) -> some View {
        HStack {
            Image(data: data)?
                .resizable()
                .scaledToFit()
                .bubbleStyle(isMyMessage: true, type: .imageData)
                .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            Spacer(minLength: 80)
        }
    }
    
    @ViewBuilder
    private func imageView(_ data: Data) -> some View {
        HStack {
            ZStack(alignment: .topTrailing) {
                Image(data: data)?
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(radius)
                Button {
                    withAnimation {
                        session.inputData = nil
                    }
                } label: {
                    ZStack {
                        Color.white
#if os(macOS)
                            .frame(width: 16, height: 16)
                            .cornerRadius(8)
#else
                            .frame(width: 20, height: 20)
                            .cornerRadius(10)
#endif
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.systemGray)
                    }
                }
                .padding([.top, .trailing], 6)
            }
            Spacer(minLength: 80)
        }
    }
    
    private var animationTextView: some View {
        Text("\(session.bubbleText)")
            .frame(maxWidth: .infinity, minHeight: radius * 2 - 8, alignment: .leading)
            .bubbleStyle(isMyMessage: true)
            .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            .padding(-4)
    }
    
    @ViewBuilder
    private var sendButton: some View {
        if !session.input.isEmpty || session.inputData != nil {
            Button {
                send(session.input)
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
    
}


struct ComposerInputView_Previews: PreviewProvider {
    
    @Namespace static var namespace
    
    static var previews: some View {
        ComposerInputView(session: .init(), namespace: namespace) { _ in

        }
    }

}
