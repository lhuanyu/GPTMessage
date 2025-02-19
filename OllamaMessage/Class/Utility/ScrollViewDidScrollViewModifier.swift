//
//  ScrollViewDidScrollViewModifier.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/2.
//


#if os(iOS)

import SwiftUI
import Combine

struct ScrollViewDidScrollViewModifier: ViewModifier {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var contentOffset: CGPoint = .zero
        
        var contentOffsetSubscription: AnyCancellable?
        
        func subscribe(scrollView: UIScrollView) {
            contentOffsetSubscription = scrollView.publisher(for: \.contentOffset).sink { [weak self] contentOffset in
                self?.contentOffset = contentOffset
            }
        }
    }
    
    @StateObject var viewModel = ViewModel()
    var didScroll: (CGPoint) -> Void
    
    func body(content: Content) -> some View {
        content
            .introspect(.scrollView, on: .iOS(.v16, .v17, .v18)) { scrollView in
                if viewModel.contentOffsetSubscription == nil {
                    viewModel.subscribe(scrollView: scrollView)
                }
            }
            .onReceive(viewModel.$contentOffset) { contentOffset in
                didScroll(contentOffset)
            }
    }
}

extension View {
    func didScroll(_ didScroll: @escaping (CGPoint) -> Void) -> some View {
        self.modifier(ScrollViewDidScrollViewModifier(didScroll: didScroll))
    }
}

#endif
