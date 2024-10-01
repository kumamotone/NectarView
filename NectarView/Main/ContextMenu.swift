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
            Text(NSLocalizedString("Open", comment: ""))
            Image(systemName: "folder")
        }
        .keyboardShortcut("o", modifiers: .command)

        Button(action: {
            showInFinder()
        }) {
            Text(NSLocalizedString("Show in Finder", comment: ""))
        }
        .keyboardShortcut("r", modifiers: .command)

        Divider()

        Button(action: {
            setViewMode(.single)
        }) {
            Text(NSLocalizedString("Single Page View", comment: ""))
            Image(systemName: "doc.text")
        }
        .keyboardShortcut("1", modifiers: .command)

        Button(action: {
            setViewMode(.spreadRightToLeft)
        }) {
            Text(NSLocalizedString("Spread View (Right to Left)", comment: ""))
            Image(systemName: "book.closed")
        }
        .keyboardShortcut("2", modifiers: .command)

        Button(action: {
            setViewMode(.spreadLeftToRight)
        }) {
            Text(NSLocalizedString("Spread View (Left to Right)", comment: ""))
            Image(systemName: "book")
        }
        .keyboardShortcut("3", modifiers: .command)

        Divider()

        Button(action: {
            isSettingsPresented = true
        }) {
            Text(NSLocalizedString("Settings", comment: ""))
            Image(systemName: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(action: {
            imageLoader.toggleBookmark()
        }) {
            Text(imageLoader.isCurrentPageBookmarked() ? NSLocalizedString("Remove Bookmark", comment: "") : NSLocalizedString("Add Bookmark", comment: ""))
            Image(systemName: imageLoader.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
        }
        .keyboardShortcut("b", modifiers: .command)

        Button(action: {
            imageLoader.goToNextBookmark()
        }) {
            Text(NSLocalizedString("Next Bookmark", comment: ""))
            Image(systemName: "arrow.right.to.line")
        }
        .keyboardShortcut("]", modifiers: .command)

        Button(action: {
            imageLoader.goToPreviousBookmark()
        }) {
            Text(NSLocalizedString("Previous Bookmark", comment: ""))
            Image(systemName: "arrow.left.to.line")
        }
        .keyboardShortcut("[", modifiers: .command)

        Button(action: {
            isBookmarkListPresented = true
        }) {
            Text(NSLocalizedString("Show Bookmark List", comment: ""))
            Image(systemName: "list.bullet")
        }
        .keyboardShortcut("l", modifiers: .command)

        Divider()

        Button(action: {
            imageLoader.rotateImage(by: 90)
        }) {
            Text(NSLocalizedString("Rotate 90 Degrees", comment: ""))
            Image(systemName: "rotate.right")
        }
        .keyboardShortcut("r", modifiers: .command)

        Button(action: {
            imageLoader.rotateImage(by: -90)
        }) {
            Text(NSLocalizedString("Rotate 90 Degrees Counterclockwise", comment: ""))
            Image(systemName: "rotate.left")
        }
        .keyboardShortcut("l", modifiers: .command)
    }
    
    private func setViewMode(_ mode: ViewMode) {
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
