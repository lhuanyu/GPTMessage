//
//  MessageListView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI
import SwiftUIX
import Introspect
import RegexBuilder

struct MessageListView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var session: DialogueSession
    @FocusState var isTextFieldFocused: Bool
    
    @State var isShowSettingsView = false
    
    @State var isShowClearMessagesAlert = false
    
    var body: some View {
        contentView
            .alert(
                "Warning",
                isPresented: $isShowClearMessagesAlert
            ) {
                Button(role: .destructive) {
                    session.clearMessages()
                } label: {
                    Text("Confirm")
                }
            } message: {
                Text("Remove all messages?")
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
                        isShowClearMessagesAlert = true
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
                        isShowClearMessagesAlert = true
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
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(enumerating: Array(session.conversations.enumerated())) { index, conversation in
                                    ConversationView(
                                        conversation: conversation,
                                        namespace: animation
                                    ) { conversation in
                                        Task { @MainActor in
                                            await session.retry(conversation, scroll: {
                                                scrollToBottom(proxy: proxy, anchor: $0)
                                            })
                                        }
                                    } deleteHandler: {
                                        withAnimation(after: .milliseconds(500)) {
                                            session.removeConversation(at: index)
                                            session.service.messages.remove(at: index*2)
                                            session.service.messages.remove(at: index*2)
                                        }
                                    }
                                    .id(index)
                                }
                                Text("")
                                    .frame(height: 5)
                                    .frame(maxWidth: .infinity)
                                    .id(bottomID)
                            }
                        }
    #if os(iOS)
                        .preference(key: HeightPreferenceKey.self, value: geo.frame(in: .global).height)
                        .preference(key: MaxYPreferenceKey.self, value: geo.frame(in: .global).maxY)
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
                            view.clipsToBounds = false
                        })
    #endif
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
                #if os(macOS)
                promptListView()
                #endif
            }
            .onChange(of: session.conversations.last?.errorDesc) { _ in
                withAnimation {
                    scrollToBottom(proxy: proxy)
                }
            }
#if os(iOS)
            .onAppear() {
                scrollToBottom(proxy: proxy)
            }
#else
            .onAppear() {
                scrollToBottom(proxy: proxy)
                addKeyboardEventMonitorForPromptSearching()
            }
            .onDisappear() {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
            .onChange(of: session) { _ in
                selectedPromptIndex = nil
                userHasChangedSelection = false
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: selectedPromptIndex) { index in
                guard userHasChangedSelection else {
                    return
                }
                if let index = index, index < prompts.endIndex {
                    session.input = "/\(prompts[index].cmd)"
                } else {
                    session.input = ""
                }
            }
            .onChange(of: session.input) { input in
                filterPrompts()
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
        }
    }
    
    func sendMessage(_ proxy: ScrollViewProxy) {
        if session.isReplying {
            return
        }
        Task { @MainActor in
#if os(macOS)
            if let selectedPromptIndex = selectedPromptIndex {
                userHasChangedSelection = false
                session.bubbleText = prompts[selectedPromptIndex].prompt
                session.input = prompts[selectedPromptIndex].prompt
                self.selectedPromptIndex = nil
            } else {
                session.bubbleText = session.input
            }
#else
            session.bubbleText = session.input
#endif
            session.isSending = true
            await session.send() {
                scrollToBottom(proxy: proxy, anchor: $0)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        proxy.scrollTo(bottomID, anchor: anchor)
    }
    
    
#if os(macOS)
    
    //MARK: - Search Prompt
    
    @ViewBuilder
    private func promptListView() -> some View {
        if session.input.hasPrefix("/") {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                ScrollViewReader { promptListProxy in
                    List(selection: $selectedPromptIndex) {
                        ForEach(prompts.indices, id: \.self) { index in
                            let prompt = prompts[index]
                            HStack {
                                Text("/\(prompt.cmd)")
                                    .lineLimit(1)
                                    .bold()
                                Spacer()
                                Text(prompt.act)
                                    .lineLimit(1)
                                    .foregroundColor(.secondaryLabel)
                            }
                            .id(index)
                            .tag(index)
                            .toolTip(prompt.prompt)
                        }
                    }
                    .border(.blue, width: 2)
                    .frame(height: searchListHeight)
                    .onChange(of: selectedPromptIndex) { selectedPromptIndex in
                        if let selectedPromptIndex = selectedPromptIndex {
                            promptListProxy.scrollTo(selectedPromptIndex, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(minWidth: 400, maxHeight: .infinity)
            .padding(.leading, 62)
            .padding(.trailing, 40)
            .padding(.bottom, 50)
            .onAppear() {
                selectedPromptIndex = 0
            }
            .onKeyboardShortcut(.downArrow) {
                print("down")
            }
            .onKeyboardShortcut(.upArrow) {
                print("up")
            }
        } else {
            EmptyView()
        }
    }

        
    @State var selectedPromptIndex: Int?
    
    @State var userHasChangedSelection = false
    
    @State var prompts = PromptManager.shared.prompts
    
    private var searchListHeight: CGFloat {
        min(300, max(CGFloat(prompts.count * 24) + 20, 44))
    }
    
    @State private var monitor: Any?
    
    private func addKeyboardEventMonitorForPromptSearching() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { nsevent in
            if let selectedPromptIndex = selectedPromptIndex {
                if nsevent.keyCode == 125 { // arrow down
                    self.selectedPromptIndex = selectedPromptIndex < prompts.count - 1 ? selectedPromptIndex + 1 : 0
                    userHasChangedSelection = true
                } else {
                    if nsevent.keyCode == 126 { // arrow up
                        self.selectedPromptIndex = selectedPromptIndex > 0 ? selectedPromptIndex - 1 : prompts.endIndex - 1
                        userHasChangedSelection = true
                    }
                }
            }
            return nsevent
        }
    }
    
    private func filterPrompts() {
        guard session.input.hasPrefix("/") else {
            return
        }
        
        if let selectedPromptIndex = selectedPromptIndex, prompts.endIndex > selectedPromptIndex {
            let input = session.input.dropFirst()
            if prompts[selectedPromptIndex].cmd == input {
                return
            }
        }
        
        if session.input == "/" {
            prompts = PromptManager.shared.prompts
        } else {
            let input = session.input.dropFirst()
            prompts = PromptManager.shared.prompts.filter {
                if $0.cmd.range(of: input) != nil {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
#endif
    
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
