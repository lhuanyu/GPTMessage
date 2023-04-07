//
//  ImageMessageView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI
import Kingfisher

struct ImageMessageView: View {
    
    var url: URL?
    
    var body: some View {
        KFImage(url)
            .resizable()
            .fade(duration: 0.25)
            .placeholder { p in
                ProgressView()
            }
            .cacheOriginalImage()
            .frame(maxWidth: 512, maxHeight: 512)
            .aspectRatio(.init(width: 1, height: 1), contentMode: .fit)
    }
}

struct ImageMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageMessageView()
    }
}
