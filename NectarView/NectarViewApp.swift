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
            CommandGroup(replacing: .sidebar) {
                Button("単ページ表示") {
                    imageLoader.toggleViewMode(.single)
                    appSettings.isSpreadViewEnabled = false
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("見開き表示 (左→右)") {
                    imageLoader.toggleViewMode(.spreadLeftToRight)
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = false
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("見開き表示 (右→左)") {
                    imageLoader.toggleViewMode(.spreadRightToLeft)
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = true
                }
                .keyboardShortcut("3", modifiers: .command)
            }
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
        }
    }
}
