import SwiftUI

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            ColorPicker(NSLocalizedString("BackgroundColor", comment: "BackgroundColor"), selection: $appSettings.backgroundColor)
            ColorPicker(NSLocalizedString("ControlBarColor", comment: "ControlBarColor"), selection: $appSettings.controlBarColor)
            
            Toggle(NSLocalizedString("ReverseLeftRightKey", comment: "Reverse left-right key direction"), isOn: $appSettings.isLeftRightKeyReversed)
            
            Button(NSLocalizedString("ResetSettings", comment: "ResetSettings")) {
                appSettings.resetToDefaults()
            }
            Button(NSLocalizedString("OpenTemporaryDirectory", comment: "OpenTemporaryDirectory")) {
                openTemporaryDirectory()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
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
