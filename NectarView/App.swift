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
                        .frame(width: 400, height: 300)
                }
                .sheet(isPresented: $isBookmarkListPresented) {
                    BookmarkListView(imageLoader: imageLoader, isPresented: $isBookmarkListPresented)
                }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("Settings", comment: "")) {
                    isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {
                Button(NSLocalizedString("Open", comment: "")) {
                    imageLoader.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .sidebar) {
                Button(NSLocalizedString("Single Page View", comment: "")) {
                    appSettings.isSpreadViewEnabled = false
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button(NSLocalizedString("Spread View (Right to Left)", comment: "")) {
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = true
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button(NSLocalizedString("Spread View (Left to Right)", comment: "")) {
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = false
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Divider()

                Button(NSLocalizedString("Rotate 90 Degrees", comment: "")) {
                    imageLoader.rotateImage(by: 90)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button(NSLocalizedString("Rotate 90 Degrees Counterclockwise", comment: "")) {
                    imageLoader.rotateImage(by: -90)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
            CommandMenu(NSLocalizedString("Bookmarks", comment: "")) {
                Button(NSLocalizedString("Add/Remove Bookmark", comment: "")) {
                    imageLoader.toggleBookmark()
                }
                .keyboardShortcut("b", modifiers: .command)
                
                Button(NSLocalizedString("Next Bookmark", comment: "")) {
                    imageLoader.goToNextBookmark()
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button(NSLocalizedString("Previous Bookmark", comment: "")) {
                    imageLoader.goToPreviousBookmark()
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Divider()
                
                Button(NSLocalizedString("Show Bookmark List", comment: "")) {
                    isBookmarkListPresented = true
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}
