import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("アプリケーションが起動しました")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("アプリケーションが終了します")
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("アプリケーションがアクティブになりました")
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        print("アプリケーションが非アクティブになります")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("最後のウィンドウが閉じられました")
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print("ファイルが開かれました: \(urls)")
        // ここでファイルを処理するロジックを追加できます
    }
}
