import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @State private var images: [URL] = []
    @State private var currentIndex: Int = 0
    @State private var currentImageURL: URL? = nil

    var body: some View {
        VStack {
            if let currentImageURL = currentImageURL {
                WebImage(url: currentImageURL)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Drag and drop a folder or image file here")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Button("Open Folder") {
                openFolder()
            }
            .padding()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, url.isFileURL {
                        DispatchQueue.main.async {
                            if url.hasDirectoryPath {
                                // フォルダがドロップされた場合
                                loadImages(from: url)
                            } else {
                                // ファイルがドロップされた場合
                                loadImages(fromFile: url)
                            }
                        }
                    }
                }
                return true
            }
            return false
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if handleKeyPress(event: event) {
                    return nil // イベントを処理済みとしてシステムに渡さない
                }
                return event
            }
        }
    }
    
    // フォルダから全ての画像を読み込む
    private func loadImages(from folderURL: URL) {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            self.images = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            if !self.images.isEmpty {
                self.currentIndex = 0
                self.currentImageURL = self.images[self.currentIndex]
            }
        } catch {
            print("Failed to load images from folder: \(error.localizedDescription)")
        }
    }
    
    // ファイルがドロップされた場合、そのファイルの存在するフォルダ内の画像を読み込む
    private func loadImages(fromFile fileURL: URL) {
        let folderURL = fileURL.deletingLastPathComponent() // ファイルの親フォルダを取得
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            self.images = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            if let index = self.images.firstIndex(of: fileURL) {
                self.currentIndex = index
                self.currentImageURL = self.images[self.currentIndex]
            }
        } catch {
            print("Failed to load images from folder: \(error.localizedDescription)")
        }
    }
    
    // フォルダをダイアログから開いて画像をロード
    private func openFolder() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a folder"
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == .OK, let result = dialog.url {
            loadImages(from: result)
        }
    }

    // キーボードの矢印キーで画像を切り替える処理
    private func handleKeyPress(event: NSEvent) -> Bool {
        if event.keyCode == 123 { // 左矢印キー
            showPreviousImage()
            return true // イベントを処理したことを示す
        } else if event.keyCode == 124 { // 右矢印キー
            showNextImage()
            return true // イベントを処理したことを示す
        }
        return false // その他のキーイベントは処理しなかったことを示す
    }

    // 次の画像を表示
    private func showNextImage() {
        if currentIndex < images.count - 1 {
            currentIndex += 1
            currentImageURL = images[currentIndex]
        } else {
            playSound()
        }
    }

    // 前の画像を表示
    private func showPreviousImage() {
        if currentIndex > 0 {
            currentIndex -= 1
            currentImageURL = images[currentIndex]
        } else {
            playSound()
        }
    }

    // 音を再生する関数
    private func playSound() {
        NSSound(named: "Basso")?.play()
    }
}