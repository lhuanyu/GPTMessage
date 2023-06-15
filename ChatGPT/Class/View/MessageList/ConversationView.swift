//
//  ConversationView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI
import SwiftUIX
import Kingfisher

struct AnimationID {
    
    static let senderBubble = "SenderBubble"
    
}

struct ConversationView: View {
        
    let conversation: Conversation
    let namespace: Namespace.ID
    var lastConversationDate: Date?
    let retryHandler: (Conversation) -> Void
    
    @State var isEditing = false
    @FocusState var isFocused: Bool
    @State var editingMessage: String = ""
    var deleteHandler: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            dateView
            VStack {
                message(isSender: true)
                    .padding(.leading, horizontalPadding(for: conversation.inputType)).padding(.vertical, 10)
                if conversation.reply != nil {
                    message()
                        .transition(.move(edge: .leading))
                        .padding(.trailing, horizontalPadding(for: conversation.replyType)).padding(.vertical, 10)
                }
            }
        }
        .transition(.moveAndFade)
        .padding(.horizontal, 15)
    }
    
    private func horizontalPadding(for type: MessageType) -> CGFloat {
#if os(iOS)
        type.isImage ? 105 : 55
#else
        type.isImage ? 205 : 105
#endif
    }
    
    var dateView: some View {
        HStack {
            Spacer()
            if let lastConversationDate = lastConversationDate {
                if conversation.date.timeIntervalSince(lastConversationDate) > 60  {
                    Text(conversation.date.iMessageDateTimeString)
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
            } else {
                Text(conversation.date.iMessageDateTimeString)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private var showRefreshButton: Bool {
        !conversation.isReplying && conversation.isLast
    }
    
    @ViewBuilder
    func message(isSender: Bool = false) -> some View {
        if isSender {
            senderMessage
                .contextMenu {
                    Button {
                        if let data = conversation.inputData {
                           KFCrossPlatformImage(data: data)?.copyToPasteboard()
                        } else {
                            conversation.input.copyToPasteboard()
                        }
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
            replyMessage
                .contextMenu {
                    VStack {
                        Button {
                            if let imageURL = conversation.replyImageURL {
                                ImageCache.default.retrieveImage(forKey: imageURL.absoluteString) { result in
                                    switch result {
                                    case let .success(image):
                                        image.image?.copyToPasteboard()
                                        print("copied!")
                                    case .failure:
                                        break
                                    }
                                }
                            } else if let data = conversation.replyImageData {
                                KFCrossPlatformImage(data: data)?.copyToPasteboard()
                            } else {
                                conversation.reply?.copyToPasteboard()
                            }
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
                messageEditButton()
                senderMessageContent
                    .frame(minHeight: 24)
                    .bubbleStyle(isMyMessage: true, type: conversation.inputType)
                    .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            } else {
                senderMessageContent
                    .frame(minHeight: 24)
                    .bubbleStyle(isMyMessage: true, type: conversation.inputType)
            }
        }
    }
    
    @ViewBuilder
    var senderMessageContent: some View {
        if let data = conversation.inputData {
            ImageDataMessageView(data: data)
                .maxWidth(256)
        } else {
            if isEditing {
                TextField("", text: $editingMessage, axis: .vertical)
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .lineLimit(1...20)
                    .background(.background)
            } else {
                Text(conversation.input)
                    .textSelection(.enabled)
            }
        }
    }
    
    @ViewBuilder
    func messageEditButton() -> some View {
        if conversation.isReplying || conversation.inputType.isImage {
            EmptyView()
        } else {
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
            .keyboardShortcut(isEditing ? .defaultAction : .none)
            .frame(width: 30)
            .padding(.trailing)
            .padding(.leading, -50)
        }
    }
    
    var replyMessage: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                switch conversation.replyType {
                case .text:
                    TextMessageView(text: conversation.reply ?? "", isReplying: conversation.isReplying)
                case .image:
                    ImageMessageView(url: conversation.replyImageURL)
                        .maxWidth(256)
                case .imageData:
                    ImageDataMessageView(data: conversation.replyImageData)
                        .maxWidth(256)
                case .error:
                    ErrorMessageView(error: conversation.errorDesc) {
                        retryHandler(conversation)
                    }
                }
                if conversation.isReplying {
                    ReplyingIndicatorView()
                        .frame(width: 48, height: 24)
                }
            }
            .frame(minHeight: 24)
            .bubbleStyle(isMyMessage: false, type: conversation.replyType)
            retryButton
            Spacer()
        }
    }
    
    @ViewBuilder
    var retryButton: some View {
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
    }
    
}

extension String {
    func copyToPasteboard() {
#if os(iOS)
        UIPasteboard.general.string = self
#else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self, forType: .string)
#endif
    }
}

extension KFCrossPlatformImage {
    func copyToPasteboard() {
#if os(iOS)
        UIPasteboard.general.image = self
#else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([self])
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
