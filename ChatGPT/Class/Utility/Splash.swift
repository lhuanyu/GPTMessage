//
//  Splash.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/20.
//

import MarkdownUI
import Splash
import SwiftUI

struct TextOutputFormat: OutputFormat {
    private let theme: Splash.Theme
    
    init(theme: Splash.Theme) {
        self.theme = theme
    }
    
    func makeBuilder() -> Builder {
        Builder(theme: self.theme)
    }
}

extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText: [Text]
        
        fileprivate init(theme: Splash.Theme) {
            self.theme = theme
            self.accumulatedText = []
        }
        
        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = self.theme.tokenColors[type] ?? self.theme.plainTextColor
            self.accumulatedText.append(Text(token)
                #if os(iOS)
                .foregroundColor(.init(uiColor: color))
                #endif
                #if os(macOS)
                .foregroundColor(.init(nsColor: color))
                #endif
            )
            
        }
        
        mutating func addPlainText(_ text: String) {
            self.accumulatedText.append(
                Text(text)
                #if os(iOS)
                    .foregroundColor(.init(uiColor: self.theme.plainTextColor))
                #endif
                #if os(macOS)
                    .foregroundColor(.init(nsColor: self.theme.plainTextColor))
                #endif
            )
        }
        
        mutating func addWhitespace(_ whitespace: String) {
            self.accumulatedText.append(Text(whitespace))
        }
        
        func build() -> Text {
            self.accumulatedText.reduce(Text(""), +)
        }
    }
}


struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>
    
    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }
    
    func highlightCode(_ content: String, language: String?) -> Text {
        guard language?.lowercased() == "swift" else {
            return Text(content)
        }
        
        return self.syntaxHighlighter.highlight(content)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}
