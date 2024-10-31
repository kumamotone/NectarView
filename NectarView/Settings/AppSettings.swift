import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("backgroundColor") var backgroundColor: Color = .black
    @AppStorage("controlBarColor") var controlBarColor: Color = Color.black.opacity(0.6)
    @AppStorage("isSpreadViewEnabled") var isSpreadViewEnabled: Bool = false
    @AppStorage("isRightToLeftReading") var isRightToLeftReading: Bool = false
    @Published var zoomFactor: CGFloat = 1.0
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system"
    @AppStorage("useRealisticAppearance") var useRealisticAppearance: Bool = false
    @AppStorage("customKeyboardShortcuts") private var customKeyboardShortcutsData: Data = Data()
    @AppStorage("nextPageShortcut") private var nextPageShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .rightArrow, modifiers: []))
    @AppStorage("previousPageShortcut") private var previousPageShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .leftArrow, modifiers: []))
    @AppStorage("addBookmarkShortcut") private var addBookmarkShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .b, modifiers: .command))
    @AppStorage("nextBookmarkShortcut") private var nextBookmarkShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .rightBracket, modifiers: .command))
    @AppStorage("previousBookmarkShortcut") private var previousBookmarkShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .leftBracket, modifiers: .command))
    @AppStorage("showBookmarkListShortcut") private var showBookmarkListShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .e, modifiers: .command))
    @AppStorage("zoomInShortcut") private var zoomInShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .equal, modifiers: .command))
    @AppStorage("zoomOutShortcut") private var zoomOutShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .minus, modifiers: .command))
    @AppStorage("resetZoomShortcut") private var resetZoomShortcutData: Data = try! JSONEncoder().encode(KeyboardShortcut(key: .zero, modifiers: .command))

    var customKeyboardShortcuts: [String: String] {
        get {
            guard let decoded = try? JSONDecoder().decode([String: String].self, from: customKeyboardShortcutsData) else {
                return [:]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                customKeyboardShortcutsData = encoded
            }
        }
    }

    var nextPageShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: nextPageShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .rightArrow, modifiers: [])
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                nextPageShortcutData = encoded
            }
        }
    }

    var previousPageShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: previousPageShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .leftArrow, modifiers: [])
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                previousPageShortcutData = encoded
            }
        }
    }

    var addBookmarkShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: addBookmarkShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .b, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                addBookmarkShortcutData = encoded
            }
        }
    }

    var nextBookmarkShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: nextBookmarkShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .rightBracket, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                nextBookmarkShortcutData = encoded
            }
        }
    }

    var previousBookmarkShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: previousBookmarkShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .leftBracket, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                previousBookmarkShortcutData = encoded
            }
        }
    }

    var showBookmarkListShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: showBookmarkListShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .e, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                showBookmarkListShortcutData = encoded
            }
        }
    }

    var zoomInShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: zoomInShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .equal, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                zoomInShortcutData = encoded
            }
        }
    }

    var zoomOutShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: zoomOutShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .minus, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                zoomOutShortcutData = encoded
            }
        }
    }

    var resetZoomShortcut: KeyboardShortcut {
        get {
            if let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: resetZoomShortcutData) {
                return decoded
            }
            return KeyboardShortcut(key: .zero, modifiers: .command)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                resetZoomShortcutData = encoded
            }
        }
    }

    func changeLanguage(to language: String) {
        selectedLanguage = language
        applyLanguageSetting()
        // アプリケーションを再起動する必要があることをユーザーに通知
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Language Changed", comment: "")
            alert.informativeText = NSLocalizedString("Please restart the application for the language change to take effect.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
    }

    func resetToDefaults() {
        backgroundColor = .black
        controlBarColor = Color.black.opacity(0.6)
        isSpreadViewEnabled = false
        isRightToLeftReading = false
        zoomFactor = 1.0
        selectedLanguage = "system"
        useRealisticAppearance = false
        nextPageShortcut = KeyboardShortcut(key: .rightArrow, modifiers: [])
        previousPageShortcut = KeyboardShortcut(key: .leftArrow, modifiers: [])
        addBookmarkShortcut = KeyboardShortcut(key: .b, modifiers: .command)
        nextBookmarkShortcut = KeyboardShortcut(key: .rightBracket, modifiers: .command)
        previousBookmarkShortcut = KeyboardShortcut(key: .leftBracket, modifiers: .command)
        showBookmarkListShortcut = KeyboardShortcut(key: .e, modifiers: .command)
        zoomInShortcut = KeyboardShortcut(key: .equal, modifiers: .command)
        zoomOutShortcut = KeyboardShortcut(key: .minus, modifiers: .command)
        resetZoomShortcut = KeyboardShortcut(key: .zero, modifiers: .command)
        applyLanguageSetting()
    }
    
    func applyLanguageSetting() {
        if selectedLanguage == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}
