//
//  MessageMarkdownView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/3/7.
//

import MarkdownUI
import Splash
import SwiftUI

struct MessageMarkdownView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    
    var body: some View {
        Markdown(MarkdownContent(text))
            .markdownCodeSyntaxHighlighter(.splash(theme: theme))
            .markdownImageProvider(.webImage)
            .textSelection(.enabled)
    }

    private var theme: Splash.Theme {
      // NOTE: We are ignoring the Splash theme font
      switch self.colorScheme {
      case .dark:
        return .wwdc17(withFont: .init(size: 16))
      default:
        return .sunset(withFont: .init(size: 16))
      }
    }
}


// MARK: - WebImageProvider

struct WebImageProvider: ImageProvider {
  func makeImage(url: URL?) -> some View {
    ResizeToFit {
        AsyncImage(url: url) { image in
            image
                .resizable()
        } placeholder: {
            ProgressView()
        }
    }
  }
}

extension ImageProvider where Self == WebImageProvider {
  static var webImage: Self {
    .init()
  }
}

// MARK: - ResizeToFit

/// A layout that resizes its content to fit the container **only** if the content width is greater than the container width.
struct ResizeToFit: Layout {
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard let view = subviews.first else {
      return .zero
    }

    var size = view.sizeThatFits(.unspecified)

    if let width = proposal.width, size.width > width {
      let aspectRatio = size.width / size.height
      size.width = width
      size.height = width / aspectRatio
    }
    return size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    guard let view = subviews.first else { return }
    view.place(at: bounds.origin, proposal: .init(bounds.size))
  }
}
