//
//  ConversationView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

struct AnimationID {
    
    static let senderBubble = "SenderBubble"
    
}

struct ConversationView: View {
        
    let conversation: Conversation
    let namespace: Namespace.ID
    let retryHandler: (Conversation) -> Void
    
    @State var isEditing = false
    @FocusState var isFocused: Bool
    @State var editingMessage: String = ""
    var deleteHandler: (() -> Void)?

    var body: some View {
        VStack {
            message(isSender: true)
                .padding(.leading, horizontalPadding).padding(.vertical, 10)
            if conversation.reply != nil {
                message()
                    .transition(.move(edge: .leading))
                    .padding(.trailing, horizontalPadding).padding(.vertical, 10)
            }
        }
        .transition(.moveAndFade)
        .padding(.horizontal, 15)
    }
    
    var horizontalPadding: CGFloat {
        #if os(iOS)
            55
        #else
            105
        #endif
    }
    
    var showRefreshButton: Bool {
        !conversation.isReplying && conversation.isLast
    }
    
    @ViewBuilder
    func message(isSender: Bool = false) -> some View {
        if isSender {
            senderMessage
                .contextMenu {
                    Button {
                        conversation.input.copyToPasteboard()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                    }
                    if !conversation.isReplying {
                        Button(role: .destructive) {
                            deleteHandler?()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                        }
                    }
                }
        } else {
            chatMessage
                .contextMenu {
                    VStack {
                        Button {
                            conversation.reply?.copyToPasteboard()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                        }
                        if conversation.isLast {
                            Button {
                                retryHandler(conversation)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Regenerate")
                                }
                            }
                        }
                        if !conversation.isReplying {
                            Button(role: .destructive) {
                                deleteHandler?()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                            }
                        }
                    }
                }
        }
    }
    
    var senderMessage: some View {
        HStack(spacing: 0) {
            Spacer()
            if conversation.isLast {
                if !conversation.isReplying {
                    messageEditButton()
                }
                messageContent(
                    text: conversation.input,
                    isLast: conversation.isLast,
                    isSender: true
                )
                .bubbleStyle(isMyMessage: true)
                .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            } else {
                messageContent(
                    text: conversation.input,
                    isLast: false,
                    isSender: true
                )
                .bubbleStyle(isMyMessage: true)
            }
        }
    }
    
    @ViewBuilder
    func messageEditButton() -> some View {
        Button {
            if isEditing {
                if editingMessage != conversation.input {
                    var message = conversation
                    message.input = editingMessage
                    retryHandler(message)
                }
            } else {
                editingMessage = conversation.input
            }
            isEditing.toggle()
            isFocused = isEditing
        } label: {
            if isEditing {
                Image(systemName: "checkmark")
            } else {
                Image(systemName: "pencil")
            }
        }
        .frame(width: 30)
        .padding(.trailing)
        .padding(.leading, -50)
    }
    
    var chatMessage: some View {
        HStack(spacing: 0) {
            messageContent(
                text: conversation.reply ?? "",
                errorDesc: conversation.errorDesc,
                showDotLoading: conversation.isReplying,
                isLast: conversation.isLast,
                isSender: false
            )
            .bubbleStyle(isMyMessage: false)
            if !conversation.isReplying {
                if conversation.errorDesc == nil && conversation.isLast {
                    Button {
                        retryHandler(conversation)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .frame(width: 30)
                    .padding(.leading)
                    .padding(.trailing, -50)
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func messageContent(text: String, errorDesc: String? = nil, showDotLoading: Bool = false, isLast: Bool = false, isSender: Bool = false) -> some View {
        VStack(alignment: .leading) {
            if isSender {
                if isEditing {
                    TextField("", text: $editingMessage, axis: .vertical)
                        .foregroundColor(.primary)
                        .focused($isFocused)
                        .lineLimit(1...20)
                        .background(.background)
                } else if !text.isEmpty {
                    Text(text)
                        .textSelection(.enabled)
                }
            } else if !text.isEmpty {
                if AppConfiguration.shared.isMarkdownEnabled && !conversation.isReplying {
                    MessageMarkdownView(text: text)
                        .textSelection(.enabled)
                } else {
                    Text(text)
                        .textSelection(.enabled)
                }
            }
            
            if let error = errorDesc {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                
                Button("Regenerate response") {
                    retryHandler(conversation)
                }
                .foregroundColor(.accentColor)
                .padding([.top,.bottom])
            }
            
            if showDotLoading {
                ReplyingIndicatorView()
                    .frame(width: 48, height: 24)
            }
        }
    }
    
    
}

extension String {
    func copyToPasteboard() {
#if os(iOS)
        UIPasteboard.general.string = self
#else
        NSPasteboard.general.setString(self, forType: .string)
#endif
    }
}

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
}

struct MessageRowView_Previews: PreviewProvider {
    
    static let message = Conversation(
        isReplying: true, isLast: false,
        input: "What is SwiftUI?",
        reply: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc.")
    
    static let message2 = Conversation(
        isReplying: false, isLast: false,
        input: "What is SwiftUI?",
        reply: "",
        errorDesc: "ChatGPT is currently not available")
    
    static let message3 = Conversation(
        isReplying: true, isLast: false,
        input: "What is SwiftUI?",
        reply: "")
    
    static let message4 = Conversation(
        isReplying: false, isLast: true,
        input: "What is SwiftUI?",
        reply: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc.",
        errorDesc: nil)
    
    @Namespace static  var animation
    
    static var previews: some View {
        NavigationStack {
            ScrollView {
                ConversationView(conversation: message, namespace: animation,  retryHandler: { message in
                    
                })
                ConversationView(conversation: message2, namespace: animation,  retryHandler: { message in
                    
                })
                ConversationView(conversation: message3, namespace: animation,  retryHandler: { message in
                    
                })
                ConversationView(conversation: message4, namespace: animation,  retryHandler: { message in
                    
                })
            }
            .frame(width: 400)
            .previewLayout(.sizeThatFits)
        }
    }
}
