import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("backgroundColor") var backgroundColor: Color = .black
    @AppStorage("controlBarColor") var controlBarColor: Color = Color.black.opacity(0.6)
    @AppStorage("isSpreadViewEnabled") var isSpreadViewEnabled: Bool = false
    @AppStorage("isRightToLeftReading") var isRightToLeftReading: Bool = false
    @AppStorage("isLeftRightKeyReversed") var isLeftRightKeyReversed: Bool = true
    
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
    
    func resetToDefaults() {
        backgroundColor = .black
        controlBarColor = Color.black.opacity(0.6)
        isSpreadViewEnabled = false
        isRightToLeftReading = false
        isLeftRightKeyReversed = true
    }
}

