import SwiftUI

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            ColorPicker(NSLocalizedString("BackgroundColor", comment: "BackgroundColor"), selection: $appSettings.backgroundColor)
            ColorPicker(NSLocalizedString("ControlBarColor", comment: "ControlBarColor"), selection: $appSettings.controlBarColor)
            
            Toggle(NSLocalizedString("ReverseKeyboardDirection", comment: "Reverse keyboard direction"), isOn: $appSettings.isKeyboardDirectionReversed)
            
            Button(NSLocalizedString("ResetSettings", comment: "ResetSettings")) {
                appSettings.resetToDefaults()
            }
            Button(NSLocalizedString("OpenTemporaryDirectory", comment: "OpenTemporaryDirectory")) {
                openTemporaryDirectory()
            }
        }
        .padding()
        .frame(width: 800, height: 600)
        .navigationTitle(NSLocalizedString("Settings", comment: "Settings"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(NSLocalizedString("Done", comment: "Done")) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func openTemporaryDirectory() {
        let tempDir = FileManager.default.temporaryDirectory
        NSWorkspace.shared.open(tempDir)
    }
}
