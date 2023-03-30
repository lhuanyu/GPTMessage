//
//  LeadingComposerView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/17.
//

import SwiftUI

struct LeadingComposerView: View {
    
    @Binding var defautPrompt: String
    
    @State var selectedPromt: Prompt?
    
    @State var showPromptPopover: Bool = false
    
    private var height: CGFloat {
#if os(iOS)
        22
#else
        17
#endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                
            } label: {
                Image(systemName: "camera.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .foregroundColor(.gray)
            }
#if os(iOS)
            Menu {
                ForEach(PromptManager.shared.prompts) { promt in
                    Button {
                        defautPrompt = promt.prompt
                    } label: {
                        Text(promt.act)
                    }
                }
            } label: {
                Image(systemName: "person.text.rectangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .foregroundColor(.gray)
                    .ignoresSafeArea(.keyboard)
            }
            .menuIndicator(.hidden)
            .ignoresSafeArea(.keyboard)
#endif
        }
        .macButtonStyle()
        .padding(.horizontal, 8)
        .frame(maxHeight: 32)
    }
    
}

struct LeadingComposerView_Previews: PreviewProvider {
    static var previews: some View {
        LeadingComposerView(defautPrompt: .constant(""))
            .previewLayout(.fixed(width: 400.0, height: 100.0))
        
        LeadingComposerView(defautPrompt: .constant(""))
            .previewLayout(.fixed(width: 400.0, height: 100.0))
        
        HStack(alignment: .bottom) {
            LeadingComposerView(defautPrompt: .constant(""))
            
            Capsule()
                .stroke(.gray, lineWidth: 2)
                .frame(maxHeight: 50)
            
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 400.0, height: 100.0))
        
        LeadingComposerView(defautPrompt: .constant(""))
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 400.0, height: 100.0))
    }
}

extension View {
    func macButtonStyle() -> some View {
        modifier(MacButtonModifier())
    }
}

struct MacButtonModifier: ViewModifier {
    
    func body(content: Content) -> some View {
#if os(macOS)
        content
            .buttonStyle(.borderless)
#else
        content
#endif
    }
}


struct MacTextFieldModifier: ViewModifier {
    
    func body(content: Content) -> some View {
#if os(macOS)
        content
            .buttonStyle(.borderless)
#else
        content
#endif
    }
}

