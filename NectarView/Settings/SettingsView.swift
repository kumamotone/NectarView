import SwiftUI

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            CustomTabView(content: [
                (title: NSLocalizedString("General", comment: "General tab"), icon: "gear", view: AnyView(GeneralSettingsView(appSettings: appSettings))),
                (title: NSLocalizedString("Appearance", comment: "Appearance tab"), icon: "eyeglasses", view: AnyView(AppearanceSettingsView(appSettings: appSettings))),
                (title: NSLocalizedString("Reading", comment: "Reading tab"), icon: "book", view: AnyView(ReadingSettingsView(appSettings: appSettings)))
            ])
            
            Button(NSLocalizedString("ResetSettings", comment: "ResetSettings")) {
                appSettings.resetToDefaults()
            }
            .padding()
        }
        .frame(width: 600, height: 400)
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

struct GeneralSettingsView: View {
    @ObservedObject var appSettings: AppSettings
    
    var body: some View {
        Form {
            Picker(NSLocalizedString("Select Language", comment: "Language picker label"), selection: $appSettings.selectedLanguage) {
                Text(NSLocalizedString("System Default", comment: "System default language option")).tag("system")
                Text("English").tag("en")
                Text("日本語").tag("ja")
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: appSettings.selectedLanguage) { _, newValue in
                appSettings.changeLanguage(to: newValue)
            }
        }
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var appSettings: AppSettings
    
    var body: some View {
        Form {
            ColorPicker(NSLocalizedString("BackgroundColor", comment: "BackgroundColor"), selection: $appSettings.backgroundColor)
            ColorPicker(NSLocalizedString("ControlBarColor", comment: "ControlBarColor"), selection: $appSettings.controlBarColor)
        }
        .padding()
    }
}

struct ReadingSettingsView: View {
    @ObservedObject var appSettings: AppSettings
    
    var body: some View {
        Form {
            Toggle(NSLocalizedString("Enable Spread View", comment: "Enable spread view toggle"), isOn: $appSettings.isSpreadViewEnabled)
            Toggle(NSLocalizedString("Right to Left Reading", comment: "Right to left reading toggle"), isOn: $appSettings.isRightToLeftReading)
            Toggle(NSLocalizedString("useLeftKeyToGoNextWhenSinglePageWhenSinglePage", comment: "Reverse left-right key direction"), isOn: $appSettings.useLeftKeyToGoNextWhenSinglePage)
            Toggle(NSLocalizedString("UseRealisticAppearance", comment: "Use realistic appearance toggle"), isOn: $appSettings.useRealisticAppearance)
        }
        .padding()
    }
}
