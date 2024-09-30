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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSettingsPresented = false
    @StateObject private var appSettings = AppSettings()
    @StateObject private var imageLoader = ImageLoader()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView(imageLoader: imageLoader)
                .environmentObject(appSettings)
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView(appSettings: appSettings)
                        .frame(width: 300, height: 300)
                }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("Settings", comment: "Settings")) {
                    isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {
                Button("開く") {
                    imageLoader.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
