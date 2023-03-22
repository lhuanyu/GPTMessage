//
//  MessageListView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI
import SwiftUIX
import Introspect

struct MessageListView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.SaveAction) var saveAction
    @ObservedObject var session: DialogueSession
    @FocusState var isTextFieldFocused: Bool
    
    @State var isShowSettingsView = false
    
    var body: some View {
        contentView
            .onChange(of: isShowSettingsView) { show in
                if !show {
                    saveAction?()
                }
            }
#if os(iOS)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        isShowSettingsView = true
                    } label: {
                        HStack(spacing: 0) {
                            Text(session.configuration.model.rawValue)
                                .bold()
                                .foregroundColor(.label)
                            Image(systemName:"chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $isShowSettingsView) {
                        DialogueSettingsView(configuration: $session.configuration)
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        guard !session.isReplying else { return }
                        session.clearMessages()
                        saveAction?()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
#else
            .navigationTitle(session.configuration.model.rawValue)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        guard !session.isReplying else { return }
                        session.clearMessages()
                        saveAction?()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
#endif
    }
    
    @State var scrollViewHeight: CGFloat?
    
    @State var scrollViewMaxY: CGFloat?
    
    @State var keyboadWillShow = false
    
    @Namespace var animation
    
    private let bottomID = "bottomID"
    
    var contentView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let frame = geo.frame(in: .global)
                    let height = frame.height
                    let maxY = frame.maxY
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(enumerating: Array(session.conversations.enumerated())) { index, conversation in
                                ConversationView(
                                    conversation: conversation,
                                    namespace: animation
                                ) { conversation in
                                    Task { @MainActor in
                                        await session.retry(conversation)
                                    }
                                } editHandler: { conversation in
                                    Task { @MainActor in
                                        await session.edit(conversation)
                                    }
                                } deleteHandler: {
                                    withAnimation(after: .milliseconds(500)) {
                                        print(session.conversations.remove(at: index))
                                        print(session.service.messages.remove(at: index*2))
                                        print(session.service.messages.remove(at: index*2))
                                        saveAction?()
                                    }
                                }
                                .id(index)
                            }
                            Text("")
                                .frame(maxWidth: .infinity)
                                .id(bottomID)
                        }
                    }
                    .preference(key: HeightPreferenceKey.self, value: height)
                    .preference(key: MaxYPreferenceKey.self, value: maxY)
                    .onPreferenceChange(HeightPreferenceKey.self) { value in
                        if let value = value {
                            if keyboadWillShow {
                                keyboadWillShow = false
                                withAnimation(.easeOut(duration: 0.1), after: .milliseconds(60)) {
                                    scrollToBottom(proxy: proxy)
                                }
                            }
                            scrollViewHeight = value
                        }
                    }
                    .onPreferenceChange(MaxYPreferenceKey.self) { value in
                        if let value = value {
                            if let scrollViewMaxY = scrollViewMaxY  {
                                let delta = scrollViewMaxY - value
                                if delta > 0 && delta < 30 {
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        scrollToBottom(proxy: proxy)
                                    }
                                }
                            }
                            scrollViewMaxY = value
                        }
                    }
                    .introspectScrollView(customize: { view in
#if os(iOS)
                        view.clipsToBounds = false
#else
                        view.layer?.masksToBounds = false
#endif
                    })
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                BottomInputView(
                    session: session,
                    namespace: animation,
                    isTextFieldFocused: _isTextFieldFocused
                ) { _ in
                    sendMessage(proxy)
                }
                .onChange(of: session.conversations.count) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                        session.isSending = false
                        session.bubbleText = ""
                    }
                }
            }
            .onChange(of: session.conversations.last?.errorDesc) { _ in
                withAnimation {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onAppear() {
                scrollToBottom(proxy: proxy)
            }
#if os(macOS)
            .onChange(of: session) { _ in
                scrollToBottom(proxy: proxy)
            }
#endif
#if os(iOS)
            .onReceive(keyboardWillChangePublisher) { value in
                if isTextFieldFocused && value {
                    self.keyboadWillShow = value
                }
            }.onReceive(keyboardDidChangePublisher) { value in
                if isTextFieldFocused {
                    if value {
                        withAnimation(.easeOut(duration: 0.1)) {
                            scrollToBottom(proxy: proxy)
                        }
                    } else {
                        self.keyboadWillShow = false
                    }
                }
            }
#endif
            .onChange(of: session.isReplying) { isReplying in
                if !isReplying {
                    saveAction?()
                }
            }
        }
    }
    
    func sendMessage(_ proxy: ScrollViewProxy) {
        if session.isReplying {
            return
        }
        Task { @MainActor in
            session.bubbleText = session.input
            session.isSending = true
            await session.send() {
                scrollToBottom(proxy: proxy, anchor: $0)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        proxy.scrollTo(bottomID, anchor: anchor)
    }
}

#if os(iOS)
extension MessageListView: KeyboardReadable {
    
}
#endif

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

struct MaxYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}
