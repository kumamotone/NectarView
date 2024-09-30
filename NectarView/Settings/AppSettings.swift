import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("backgroundColor") var backgroundColor: Color = .black
    @AppStorage("controlBarColor") var controlBarColor: Color = Color.black.opacity(0.6)
    @AppStorage("isSpreadViewEnabled") var isSpreadViewEnabled: Bool = false
    @AppStorage("isRightToLeftReading") var isRightToLeftReading: Bool = false
    @AppStorage("isLeftRightKeyReversed") var isLeftRightKeyReversed: Bool = true
    
    var body: some View {
        VStack {
            ColorPicker("Background Color", selection: $backgroundColor)
            ColorPicker("Control Bar Color", selection: $controlBarColor)
            Toggle("Enable Spread View", isOn: $isSpreadViewEnabled)
            Toggle("Right to Left Reading", isOn: $isRightToLeftReading)
            Toggle("Reverse Left/Right Keys", isOn: $isLeftRightKeyReversed)
            
            Button("Reset to Defaults") { [self] in
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

