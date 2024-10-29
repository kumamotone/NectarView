import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {        
        let appSettings = AppSettings()
        appSettings.applyLanguageSetting()

        // 編集メニューは不要なので削除する
        // うまくいっていないように見える…
        if let mainMenu = NSApp.mainMenu {
            if let editMenu = mainMenu.items.first(where: { $0.title == NSLocalizedString("Edit", comment: "Edit") }) {
                mainMenu.removeItem(editMenu)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
    }

    func applicationDidBecomeActive(_ notification: Notification) {
    }

    func applicationWillResignActive(_ notification: Notification) {
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let window = NSApplication.shared.windows.first {
            if let hostingView = window.contentView as? NSHostingView<ContentView> {
                let contentView = hostingView.rootView
                contentView.imageLoader.loadImages(from: urls[0])
                
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
