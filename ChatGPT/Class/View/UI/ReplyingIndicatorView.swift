//
//  ReplyingIndicatorView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

struct ReplyingIndicatorView: View {
    
    @State private var showLeftDot = false
    @State private var showMiddleDot = false
    @State private var showRightDot = false
    
    var body: some View {
        HStack {
            Circle()
                .opacity(showLeftDot ? 1 : 0)
            Circle()
                .opacity(showMiddleDot ? 1 : 0)
            Circle()
                .opacity(showRightDot ? 1 : 0)
        }
        .foregroundColor(.gray.opacity(0.5))
        .onAppear { performAnimation() }
    }
    
    func performAnimation() {
        let animation = Animation.easeInOut(duration: 0.4)
        withAnimation(animation) {
            showLeftDot = true
            showRightDot = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation) {
                self.showMiddleDot = true
                self.showLeftDot = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(animation) {
                self.showMiddleDot = false
                self.showRightDot = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.performAnimation()
        }
    }
}

struct DotLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ReplyingIndicatorView()
    }
}

