//
//  NectarViewApp.swift
//  NectarView
//
//  Created by 熊本和正 on 2024/09/24.
//

import SwiftUI
import SwiftData

@main
struct NectarViewApp: App {
    init() {
        // ネットワーク設定の読み込みを無効化
        UserDefaults.standard.set(false, forKey: "NSFileManagerShouldReadNetworkSettings")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
