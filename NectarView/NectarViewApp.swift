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
    @StateObject private var appSettings = AppSettings()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSettingsPresented = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView(appSettings: appSettings)
                        .frame(width: 300, height: 150)
                }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("Settings", comment: "Settings")) {
                    isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
