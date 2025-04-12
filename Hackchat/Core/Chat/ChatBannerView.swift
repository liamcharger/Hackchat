//
//  ChatBannerView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/28/25.
//

import SwiftUI

enum BannerType {
    case error
    case warning
    case info
}

struct Banner {
    let title: LocalizedStringKey
    let icon: String
    let subtitle: LocalizedStringKey?
    let type: BannerType
    
    init(title: LocalizedStringKey, icon: String, subtitle: LocalizedStringKey? = nil, type: BannerType = .warning) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.type = type
    }
}

struct ChatBannerView: View {
    let banner: Banner
    let accent: Color
    let dismiss: (() -> Void)?
    
    init(_ banner: Banner, dismiss: (() -> Void)? = nil) {
        self.banner = banner
        self.dismiss = dismiss
        
        var color = Color.orange
        switch banner.type {
        case .error:
            color = .red
        case .warning:
            break
        case .info:
            color = .blue
        }
        self.accent = color
    }
    
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: banner.icon)
                .font(.title.weight(.medium))
            VStack(alignment: .leading) {
                Text(banner.title)
                    .fontWeight(.bold)
                if let subtitle = banner.subtitle {
                    Text(subtitle)
                        .foregroundStyle(accent.opacity(0.9))
                }
            }
            if let dismiss {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 19, weight: .medium))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .foregroundStyle(accent)
        .background(accent.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(accent.opacity(0.3), lineWidth: 1)
        }
    }
}

#Preview {
    ChatBannerView(Banner(title: "Messages cannot be sent", icon: "wifi.slash", subtitle: "Your internet connection appears to be offline."))
}
