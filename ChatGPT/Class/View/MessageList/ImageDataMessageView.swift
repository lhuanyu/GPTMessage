//
//  ImageDataMessageView.swift
//  ChatGPT
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct ImageDataMessageView: View {
    
    var data: Data?
    
    var body: some View {
        if let data = data {
            Image(data: data)?
                .resizable()
                .sizeToFit()
        } else {
            EmptyView()
        }
    }
}

struct ImageDataMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDataMessageView()
    }
}
