import SwiftUI
import SwiftData

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSettingsPresented = false
    @State private var isBookmarkListPresented = false
    @StateObject private var appSettings = AppSettings()
    @StateObject private var imageLoader = ImageLoader()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView(imageLoader: imageLoader)
                .environmentObject(appSettings)
                .onAppear {
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView(appSettings: appSettings)
                        .frame(width: 300, height: 300)
                }
                .sheet(isPresented: $isBookmarkListPresented) {
                    BookmarkListView(imageLoader: imageLoader, isPresented: $isBookmarkListPresented)
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
                    appSettings.isSpreadViewEnabled = false
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("見開き表示 (右→左)") {
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = true
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("見開き表示 (左→右)") {
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = false
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Divider()

                Button("90度回転") {
                    imageLoader.rotateImage(by: 90)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("反時計回りに90度回転") {
                    imageLoader.rotateImage(by: -90)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
            CommandMenu("ブックマーク") {
                Button("ブックマークを追加/削除") {
                    imageLoader.toggleBookmark()
                }
                .keyboardShortcut("b", modifiers: .command)
                
                Button("次のブックマークへ") {
                    imageLoader.goToNextBookmark()
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("前のブックマークへ") {
                    imageLoader.goToPreviousBookmark()
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Divider()
                
                Button("ブックマークリストを表示") {
                    isBookmarkListPresented = true
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}
