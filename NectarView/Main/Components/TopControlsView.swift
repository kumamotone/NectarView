import SwiftUI

// 上部のコントロール群
struct TopControlsView: View {
    @Binding var isVisible: Bool
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var imageLoader: ImageLoader
    @Binding var isAutoScrolling: Bool
    @Binding var autoScrollInterval: Double
    let toggleAutoScroll: () -> Void
    let toggleSidebar: () -> Void

    var body: some View {
        if isVisible {
            HStack(spacing: 15) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(TopControlButtonStyle())
                .instantTooltip(NSLocalizedString("Toggle Sidebar", comment: ""))

                Spacer()
                AutoScrollControls(isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll)
                BookmarkButton(imageLoader: imageLoader)
                ViewModeButton(appSettings: appSettings, imageLoader: imageLoader)
                ReadingDirectionButton(appSettings: appSettings, imageLoader: imageLoader)
            }
            .padding(.top, 10)
            .padding(.horizontal, 10)
            .transition(.move(edge: .top))
        }
    }
}

// 自動ページめくりのコントロール
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
            .instantTooltip(isAutoScrolling ? NSLocalizedString("Stop Auto Page Turn", comment: "") : NSLocalizedString("Start Auto Page Turn", comment: ""))

            Slider(value: $autoScrollInterval, in: 0.5...30.0, step: 0.5)
                .frame(width: 80)
                .accentColor(.white)
                .instantTooltip(NSLocalizedString("Set Auto Page Turn Interval (0.5 to 30 seconds)", comment: ""))
            Text(String(format: NSLocalizedString("%.1f seconds", comment: ""), autoScrollInterval))
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
        .instantTooltip(NSLocalizedString("Auto Page Turn Settings", comment: ""))
    }
}

// 見開き/単ページのコントロール
struct ViewModeButton: View {
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        Button(action: {
            appSettings.isSpreadViewEnabled.toggle()
            imageLoader.updateViewMode(appSettings: appSettings)
        }) {
            Image(systemName: appSettings.isSpreadViewEnabled ? "book.fill" : "doc.text.fill")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip(NSLocalizedString("Single Page/Spread View", comment: ""))
    }
}

// 読み込み方向のコントロール
struct ReadingDirectionButton: View {
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        Button(action: {
            appSettings.isRightToLeftReading.toggle()
            imageLoader.updateViewMode(appSettings: appSettings)
        }) {
            Image(systemName: appSettings.isRightToLeftReading ? "arrow.left" : "arrow.right")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip(NSLocalizedString("Reading Direction", comment: ""))
    }
}

// 上部のボタンのスタイル
struct TopControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// ブックマークボタン
struct BookmarkButton: View {
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        Button(action: {
            imageLoader.toggleBookmark()
        }) {
            Image(systemName: imageLoader.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip(NSLocalizedString("Add/Remove Bookmark", comment: ""))
    }
}
