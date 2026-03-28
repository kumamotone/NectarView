import SwiftUI

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings()

    var body: some View {
        TabView {
            GeneralSettingsView(appSettings: appSettings)
                .tabItem {
                    Label(NSLocalizedString("General", comment: "General tab"), systemImage: "gear")
                }

            AppearanceSettingsView(appSettings: appSettings)
                .tabItem {
                    Label(NSLocalizedString("Appearance", comment: "Appearance tab"), systemImage: "eyeglasses")
                }

            ReadingSettingsView(appSettings: appSettings)
                .tabItem {
                    Label(NSLocalizedString("Reading", comment: "Reading tab"), systemImage: "book")
                }
        }
        .frame(width: 450, height: 250)
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
            .onChange(of: appSettings.selectedLanguage) { _, newValue in
                appSettings.changeLanguage(to: newValue)
            }

            Section {
                Button(NSLocalizedString("ResetSettings", comment: "ResetSettings")) {
                    appSettings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Form {
            Section {
                ColorPicker(NSLocalizedString("BackgroundColor", comment: "BackgroundColor"), selection: $appSettings.backgroundColor)
                ColorPicker(NSLocalizedString("ControlBarColor", comment: "ControlBarColor"), selection: $appSettings.controlBarColor)
            }
        }
        .formStyle(.grouped)
    }
}

struct ReadingSettingsView: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Form {
            Section(NSLocalizedString("ViewMode", comment: "View mode section")) {
                Toggle(NSLocalizedString("Enable Spread View", comment: "Enable spread view toggle"), isOn: $appSettings.isSpreadViewEnabled)
                Toggle(NSLocalizedString("Right to Left Reading", comment: "Right to left reading toggle"), isOn: $appSettings.isRightToLeftReading)
                    .disabled(!appSettings.isSpreadViewEnabled)
            }

            Section(NSLocalizedString("Navigation", comment: "Navigation section")) {
                Toggle(NSLocalizedString("useLeftKeyToGoNextWhenSinglePage", comment: "Reverse left-right key direction"), isOn: $appSettings.useLeftKeyToGoNextWhenSinglePage)
            }

            Section(NSLocalizedString("Appearance", comment: "Appearance section")) {
                Toggle(NSLocalizedString("UseRealisticAppearance", comment: "Use realistic appearance toggle"), isOn: $appSettings.useRealisticAppearance)
            }
        }
        .formStyle(.grouped)
    }
}
