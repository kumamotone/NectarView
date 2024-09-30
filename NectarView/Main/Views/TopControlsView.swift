import SwiftUI

struct TopControlsView: View {
    @Binding var isVisible: Bool
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var imageLoader: ImageLoader
    @Binding var isAutoScrolling: Bool
    @Binding var autoScrollInterval: Double
    let toggleAutoScroll: () -> Void

    var body: some View {
        if isVisible {
            HStack(spacing: 15) {
                Spacer()
                AutoScrollControls(isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll)
                ViewModeButton(appSettings: appSettings)
                ReadingDirectionButton(appSettings: appSettings)
            }
            .padding(.top, 10)
            .padding(.trailing, 10)
            .transition(.move(edge: .top))
        }
    }
}

struct AutoScrollControls: View {
    @Binding var isAutoScrolling: Bool
    @Binding var autoScrollInterval: Double
    let toggleAutoScroll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggleAutoScroll) {
                Image(systemName: isAutoScrolling ? "pause.fill" : "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())
            .instantTooltip(isAutoScrolling ? "自動ページめくりを停止" : "自動ページめくりを開始")

            Slider(value: $autoScrollInterval, in: 0.5...30.0, step: 0.5)
                .frame(width: 80)
                .accentColor(.white)
                .instantTooltip("自動ページめくりの間隔を設定（0.5秒〜30秒）")
            Text(String(format: "%.1f秒", autoScrollInterval))
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
        .instantTooltip("自動ページめくりの設定")
    }
}

struct ViewModeButton: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Button(action: {
            appSettings.isSpreadViewEnabled.toggle()
        }) {
            Image(systemName: appSettings.isSpreadViewEnabled ? "book.fill" : "doc.text.fill")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip("単ページ/見開き")
    }
}

struct ReadingDirectionButton: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Button(action: {
            appSettings.isRightToLeftReading.toggle()
        }) {
            Image(systemName: appSettings.isRightToLeftReading ? "arrow.left" : "arrow.right")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip("方向")
    }
}

