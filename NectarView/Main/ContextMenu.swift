import SwiftUI

// コンテキスト(右クリック)メニュー
struct ContextMenuContent: View {
    @ObservedObject var imageLoader: ImageLoader
    @Binding var isSettingsPresented: Bool
    @Binding var isBookmarkListPresented: Bool
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Button(action: {
            openFile()
        }) {
            Text("開く")
            Image(systemName: "folder")
        }
        .keyboardShortcut("o", modifiers: .command)

        Button(action: {
            showInFinder()
        }) {
            Text("Finder に表示")
        }
        .keyboardShortcut("r", modifiers: .command)

        Divider()

        Button(action: {
            setViewMode(.single)
        }) {
            Text("単ページ表示")
            Image(systemName: "doc.text")
        }
        .keyboardShortcut("1", modifiers: .command)

        Button(action: {
            setViewMode(.spreadRightToLeft)
        }) {
            Text("見開き表示 (右→左)")
            Image(systemName: "book.closed")
        }
        .keyboardShortcut("2", modifiers: .command)

        
        Button(action: {
            setViewMode(.spreadLeftToRight)
        }) {
            Text("見開き表示 (左→右)")
            Image(systemName: "book")
        }
        .keyboardShortcut("3", modifiers: .command)

        Divider()

        Button(action: {
            isSettingsPresented = true
        }) {
            Text("設定")
            Image(systemName: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(action: {
            imageLoader.toggleBookmark()
        }) {
            Text(imageLoader.isCurrentPageBookmarked() ? "ブックマークを解除" : "ブックマークを追加")
            Image(systemName: imageLoader.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
        }
        .keyboardShortcut("b", modifiers: .command)

        Button(action: {
            imageLoader.goToNextBookmark()
        }) {
            Text("次のブックマークへ")
            Image(systemName: "arrow.right.to.line")
        }
        .keyboardShortcut("]", modifiers: .command)

        Button(action: {
            imageLoader.goToPreviousBookmark()
        }) {
            Text("前のブックマークへ")
            Image(systemName: "arrow.left.to.line")
        }
        .keyboardShortcut("[", modifiers: .command)

        Button(action: {
            isBookmarkListPresented = true
        }) {
            Text("ブックマークリストを表示")
            Image(systemName: "list.bullet")
        }
        .keyboardShortcut("l", modifiers: .command)

        Divider()

        Button(action: {
            imageLoader.rotateImage(by: 90)
        }) {
            Text("90度回転")
            Image(systemName: "rotate.right")
        }
        .keyboardShortcut("r", modifiers: .command)

        Button(action: {
            imageLoader.rotateImage(by: -90)
        }) {
            Text("反時計回りに90度回転")
            Image(systemName: "rotate.left")
        }
        .keyboardShortcut("l", modifiers: .command)
    }
    
    private func setViewMode(_ mode: ImageLoader.ViewMode) {
        switch mode {
        case .single:
            appSettings.isSpreadViewEnabled = false
        case .spreadLeftToRight:
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
        case .spreadRightToLeft:
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = true
        }
        imageLoader.updateViewMode(appSettings: appSettings)
    }
    
    private func openFile() {
        imageLoader.openFile()
    }
    
    private func showInFinder() {
        if let zipFileURL = imageLoader.zipFileURL {
            // ZIPファイルの場合、ZIPファイル自体を表示
            NSWorkspace.shared.activateFileViewerSelecting([zipFileURL])
        } else if let currentImageIndex = imageLoader.currentImages.0,
                  currentImageIndex < imageLoader.images.count {
            // 通常のファイルの場合、現在の画像を表示
            NSWorkspace.shared.activateFileViewerSelecting([imageLoader.images[currentImageIndex]])
        } else {
            // 画像が読み込めていない場合
            print("表示できる画像またはZIPファイルがありません")
        }
    }
}
