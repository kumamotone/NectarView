import SwiftUI

struct ContentView_Menus: Commands {
    @Binding var isSettingsPresented: Bool

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("設定") {
                isSettingsPresented = true
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        
        CommandMenu("ファイル") {
            Button("開く...") {
                openFileOrFolder()
            }
            .keyboardShortcut("O", modifiers: .command)
        }
    }
    
    private func openFileOrFolder() {
        let dialog = NSOpenPanel()
        dialog.title = "ファイルまたはフォルダを選択"
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == .OK, let result = dialog.url {
            // Note: This needs to be updated to use the ImageLoader
            // You might need to pass the ImageLoader instance to this struct
            // or use some form of dependency injection
        }
    }
}
