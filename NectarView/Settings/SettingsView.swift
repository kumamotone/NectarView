import SwiftUI

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("Language", comment: "Language section header"))) {
                Picker(NSLocalizedString("Select Language", comment: "Language picker label"), selection: $appSettings.selectedLanguage) {
                    Text(NSLocalizedString("System Default", comment: "System default language option")).tag("system")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: appSettings.selectedLanguage) { _, newValue in
                    appSettings.changeLanguage(to: newValue)
                }
            }

            Section(header: Text(NSLocalizedString("Colors", comment: "Colors section header"))) {
                ColorPicker(NSLocalizedString("BackgroundColor", comment: "BackgroundColor"), selection: $appSettings.backgroundColor)
                ColorPicker(NSLocalizedString("ControlBarColor", comment: "ControlBarColor"), selection: $appSettings.controlBarColor)
            }

            Section(header: Text(NSLocalizedString("Reading Options", comment: "Reading options section header"))) {
                Toggle(NSLocalizedString("Enable Spread View", comment: "Enable spread view toggle"), isOn: $appSettings.isSpreadViewEnabled)
                Toggle(NSLocalizedString("Right to Left Reading", comment: "Right to left reading toggle"), isOn: $appSettings.isRightToLeftReading)
                Toggle(NSLocalizedString("ReverseLeftRightKey", comment: "Reverse left-right key direction"), isOn: $appSettings.isLeftRightKeyReversed)
            }

            Section {
                Button(NSLocalizedString("ResetSettings", comment: "ResetSettings")) {
                    appSettings.resetToDefaults()
                }
            }
        }
        .padding()
        .navigationTitle(NSLocalizedString("Settings", comment: "Settings"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(NSLocalizedString("Done", comment: "Done")) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
