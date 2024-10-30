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
