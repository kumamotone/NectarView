import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("backgroundColor") var backgroundColor: Color = .black
    @AppStorage("controlBarColor") var controlBarColor: Color = Color.black.opacity(0.6)
    @AppStorage("isSpreadViewEnabled") var isSpreadViewEnabled: Bool = false
    @AppStorage("isRightToLeftReading") var isRightToLeftReading: Bool = false
    @AppStorage("isLeftRightKeyReversed") var isLeftRightKeyReversed: Bool = true
    @Published var zoomFactor: CGFloat = 1.0
    // 他のプロパティは変更なし
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system"

    var body: some View {
        VStack {
            ColorPicker(NSLocalizedString("BackgroundColor", comment: ""), selection: $backgroundColor)
            ColorPicker(NSLocalizedString("ControlBarColor", comment: ""), selection: $controlBarColor)
            Toggle(NSLocalizedString("Enable Spread View", comment: ""), isOn: $isSpreadViewEnabled)
            Toggle(NSLocalizedString("Right to Left Reading", comment: ""), isOn: $isRightToLeftReading)
            Toggle(NSLocalizedString("Reverse Left/Right Keys", comment: ""), isOn: $isLeftRightKeyReversed)
            
            Button(NSLocalizedString("Reset to Defaults", comment: "")) { [self] in
                resetToDefaults()
            }
        }
        .padding()
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
        isLeftRightKeyReversed = true
        zoomFactor = 1.0
        
        selectedLanguage = "system"
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
