import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let removeMenuTitles = Set([NSLocalizedString("View", comment: "View"), NSLocalizedString("Edit", comment: "Edit")])

        if let mainMenu = NSApp.mainMenu {
            let menus = mainMenu.items.filter { item in
                return removeMenuTitles.contains(item.title)
            }
            for menu in menus {
                mainMenu.removeItem(menu)
            }
        }
        
        let appSettings = AppSettings()
        appSettings.applyLanguageSetting()
        let currentLanguage = Locale.current.language.languageCode?.identifier ?? "Unknown"
        print("Current Language: \(currentLanguage)")
        
//        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
//        UserDefaults.standard.synchronize()
//        let currentLanguage = Locale.preferredLanguages.first ?? "Unknown"
//        print("Current Language: \(currentLanguage)")

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
    }
}
