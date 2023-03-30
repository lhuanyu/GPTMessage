//
//  ToolTipView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/30.
//

#if os(macOS)
import SwiftUI
import AppKit

extension View {
    func toolTip(_ tip: String) -> some View {
        background(GeometryReader { childGeometry in
            TooltipView(tip, geometry: childGeometry) {
                self
            }
        })
    }
}

private struct TooltipView<Content>: View where Content: View {
    let content: () -> Content
    let tip: String
    let geometry: GeometryProxy

    init(_ tip: String, geometry: GeometryProxy, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.tip = tip
        self.geometry = geometry
    }

    var body: some View {
        ToolTip(tip, content: content)
            .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

private struct ToolTip<Content: View>: NSViewRepresentable {
    typealias NSViewType = NSHostingView<Content>

    init(_ text: String?, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }

    let text: String?
    let content: Content

    func makeNSView(context _: Context) -> NSHostingView<Content> {
        NSViewType(rootView: content)
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context _: Context) {
        nsView.rootView = content
        nsView.toolTip = text
    }
}
#endif
