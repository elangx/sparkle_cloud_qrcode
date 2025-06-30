//
//  main_tab_view.swift
//  sparkle_cloud_qrcode
//
//  Created by Ethan on 2025/6/30.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            PicSwitchSampleView()
                .tabItem {
                    Label("Fusion", systemImage: "paintpalette")
                }
            QRCodeGeneratorView()
                .tabItem {
                    Label("QrCode", systemImage: "qrcode")
                }
            
            FinalView()
                .tabItem {
                    Label("Generate", systemImage: "circle.dotted.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
}
