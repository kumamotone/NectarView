import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("backgroundColor") var backgroundColor: Color = .black
    @AppStorage("controlBarColor") var controlBarColor: Color = Color.black.opacity(0.6)
    @AppStorage("isSpreadViewEnabled") var isSpreadViewEnabled: Bool = false
    @AppStorage("isRightToLeftReading") var isRightToLeftReading: Bool = false
    @AppStorage("useLeftKeyToGoNextWhenSinglePage") var useLeftKeyToGoNextWhenSinglePage: Bool = true
    @Published var zoomFactor: CGFloat = 1.0
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system"
    @AppStorage("useRealisticAppearance") var useRealisticAppearance: Bool = false

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
        useLeftKeyToGoNextWhenSinglePage = true
        zoomFactor = 1.0
        selectedLanguage = "system"
        useRealisticAppearance = false
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
