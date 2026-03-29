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

            TipJarSettingsView()
                .tabItem {
                    Label("Tip Jar", systemImage: "heart.fill")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var appSettings: AppSettings

    private let languages: [(tag: String, name: String)] = [
        ("system", NSLocalizedString("System Default", comment: "")),
        ("en", "English"),
        ("ja", "日本語"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("ko", "한국어"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("es", "Español"),
        ("pt-BR", "Português (Brasil)"),
        ("it", "Italiano"),
        ("nl", "Nederlands"),
        ("pl", "Polski"),
        ("tr", "Türkçe"),
        ("ru", "Русский"),
        ("th", "ไทย"),
        ("vi", "Tiếng Việt"),
        ("id", "Bahasa Indonesia"),
        ("ms", "Bahasa Melayu"),
        ("sv", "Svenska"),
        ("da", "Dansk"),
        ("nb", "Norsk bokmål"),
        ("fi", "Suomi"),
    ]

    var body: some View {
        Form {
            Picker(NSLocalizedString("Select Language", comment: "Language picker label"), selection: $appSettings.selectedLanguage) {
                ForEach(languages, id: \.tag) { lang in
                    Text(lang.name).tag(lang.tag)
                }
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

struct TipJarSettingsView: View {
    @State private var isPresented = true

    var body: some View {
        TipJarView(isPresented: $isPresented)
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
