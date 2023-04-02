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
                        NavigationStack {
                            DialogueSettingsView(configuration: $session.configuration)
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem {
                                        Button {
                                            isShowSettingsView = false
                                        } label: {
                                            Text("Done")
                                                .bold()
                                        }
                                    }
                                }
                        }
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
                                Spacer(minLength: 0)
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(session.suggestions, id: \.self) { suggestion in
                                            Button {
                                                selectedPromptIndex = nil
                                                session.input = suggestion
                                                sendMessage(proxy)
                                            } label: {
                                                Text(suggestion)
                                                    .lineLimit(1)
                                            }
                                            .padding()
                                        }
                                    }
                                }
                                .scrollIndicators(.never)
                                .frame(maxWidth: .infinity)
                                .id(bottomID)
                            }
                            .frame(minHeight: geo.size.height)
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
                promptListView()
            }
            .onChange(of: session.conversations.last?.errorDesc) { _ in
                withAnimation {
                    scrollToBottom(proxy: proxy)
                }
            }
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
            .onAppear() {
                scrollToBottom(proxy: proxy)
                if session.suggestions.isEmpty {
                    session.createSuggestions() {
                        scrollToBottom(proxy: proxy, anchor: $0)
                    }
                }
            }
            .onChange(of: session) { session in
                scrollToBottom(proxy: proxy)
                if session.suggestions.isEmpty {
                    session.createSuggestions() {
                        scrollToBottom(proxy: proxy, anchor: $0)
                    }
                }
            }
#else
            .onAppear() {
                scrollToBottom(proxy: proxy)
                addKeyboardEventMonitorForPromptSearching()
                if session.suggestions.isEmpty {
                    session.createSuggestions() {
                        scrollToBottom(proxy: proxy, anchor: $0)
                    }
                }
            }
            .onDisappear() {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
            .onChange(of: session) { session in
                selectedPromptIndex = nil
                userHasChangedSelection = false
                scrollToBottom(proxy: proxy)
                if session.suggestions.isEmpty {
                    session.createSuggestions() {
                        scrollToBottom(proxy: proxy, anchor: $0)
                    }
                }
            }
#endif
            .onChange(of: selectedPromptIndex, perform: onSelectedPromptIndexChange)
            .onChange(of: session.input) { input in
                #if os(iOS)
                withAnimation {
                    filterPrompts()
                }
                #else
                filterPrompts()
                #endif
            }
        }
    }
    
    func sendMessage(_ proxy: ScrollViewProxy) {
        if session.isReplying {
            return
        }
        Task { @MainActor in
            if let selectedPromptIndex = selectedPromptIndex, selectedPromptIndex < prompts.endIndex {
                userHasChangedSelection = false
                session.bubbleText = prompts[selectedPromptIndex].prompt
                session.input = prompts[selectedPromptIndex].prompt
                self.selectedPromptIndex = nil
            } else {
                session.bubbleText = session.input
            }
            session.isSending = true
            await session.send() {
                scrollToBottom(proxy: proxy, anchor: $0)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        proxy.scrollTo(bottomID, anchor: anchor)
    }
    
    
    
    //MARK: - Search Prompt
    
#if os(iOS)
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

#endif
    
    @ViewBuilder
    private func promptListView() -> some View {
        if session.input.hasPrefix("/") {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                ScrollViewReader { promptListProxy in
                    List(selection: $selectedPromptIndex) {
                        if prompts.isEmpty {
                            Text("No Result")
                                .foregroundColor(.secondaryLabel)
                        } else {
                            ForEach(prompts.indices, id: \.self) { index in
                                let prompt = prompts[index]
                                HStack {
                                    Text("/\(prompt.cmd)")
                                        .lineLimit(1)
                                        .bold()
#if os(macOS)
                                    Spacer()
                                    Text(prompt.act)
                                        .lineLimit(1)
                                        .foregroundColor(.secondaryLabel)
#else
                                    if horizontalSizeClass == .regular {
                                        Spacer()
                                        Text(prompt.act)
                                            .lineLimit(1)
                                            .foregroundColor(.secondaryLabel)
                                    }
#endif
                                }
                                .id(index)
                                .tag(index)
#if os(macOS)
                                .toolTip(prompt.prompt)
#endif
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.systemBackground)
                    .border(.blue, width: 2)
                    .frame(height: promptListHeight)
#if os(macOS)
                    .onChange(of: selectedPromptIndex) { selectedPromptIndex in
                        if let selectedPromptIndex = selectedPromptIndex, userHasChangedSelection {
                            promptListProxy.scrollTo(selectedPromptIndex, anchor: .bottom)
                        }
                    }
#endif
                }
            }
            .frame(minWidth: promptListMinWidth, maxHeight: .infinity)
            .padding(.leading, promptListLeadingPadding)
            .padding(.trailing, promptListTrailingPadding)
            .padding(.bottom, 50)
#if os(macOS)
            .onAppear() {
                selectedPromptIndex = 0
            }
#endif
        } else {
            EmptyView()
        }
    }
    
    private var promptListTrailingPadding: CGFloat {
#if os(macOS)
        40
#else
        16
#endif
    }
    
    private var promptListLeadingPadding: CGFloat {
#if os(macOS)
        62
#else
        horizontalSizeClass == .regular ? 110 : 16
#endif
    }
    
    private var promptListMinWidth: CGFloat {
#if os(macOS)
        400
#else
        0
#endif
    }
    
    private var promptListHeight: CGFloat {
#if os(macOS)
        min(240, max(CGFloat(prompts.count * 24), 24))
#else
        if verticalSizeClass == .compact && isTextFieldFocused {
            return min(88, max(CGFloat(prompts.count * 44), 44))
        } else {
            return min(220, max(CGFloat(prompts.count * 44), 44))
        }
#endif
    }
    
    @State var selectedPromptIndex: Int?
    
    @State var userHasChangedSelection = false
    
    @State var prompts = PromptManager.shared.prompts
    
#if os(macOS)
    
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
    
#endif
    
    private func filterPrompts() {
        guard session.input.hasPrefix("/") else {
            selectedPromptIndex = nil
            userHasChangedSelection = false
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
            prompts = PromptManager.shared.prompts.filter { prompt in
                let p = prompt.cmd.lowercased().replacingOccurrences(of: "_", with: "")
                return p.range(of:input.lowercased()) != nil || prompt.cmd.lowercased().range(of: input.lowercased()) != nil
            }
        }
#if os(macOS)
        selectedPromptIndex = 0
#endif
    }
    
    private func onSelectedPromptIndexChange(_ index: Int?) {
#if os(macOS)
        guard userHasChangedSelection else {
            return
        }
        if let index = index, index < prompts.endIndex {
            session.input = "/\(prompts[index].cmd)"
        } else {
            session.input = ""
        }
#else
        if let index = index, index < prompts.endIndex {
            session.input = prompts[index].prompt
        }
#endif
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
