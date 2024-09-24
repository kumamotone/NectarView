import SwiftUI

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            ColorPicker("背景色", selection: $appSettings.backgroundColor)
            ColorPicker("コントロールバーの色", selection: $appSettings.controlBarColor)
            
            Button("設定をリセット") {
                appSettings.resetToDefaults()
            }
        }
        .padding()
        .frame(width: 300, height: 200) // 高さを少し増やしました
        .navigationTitle("設定")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完了") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}