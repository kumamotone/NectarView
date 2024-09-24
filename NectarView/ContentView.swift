import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @State private var images: [URL] = []
    @State private var currentIndex: Int = 0
    @State private var currentImageURL: URL? = nil
    @State private var isControlsVisible: Bool = false
    @State private var timer: Timer?
    @State private var isFullscreen: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let currentImageURL = currentImageURL {
                    WebImage(url: currentImageURL)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture(count: 2) {
                            toggleFullscreen()
                        }
                } else {
                    Text("ファイルまたはフォルダをドラッグ＆ドロップしてください")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Spacer()
                    if isControlsVisible && images.count > 0 {
                        HStack {
                            Text("\(currentIndex + 1) / \(images.count)")
                                .font(.caption)
                                .padding(.leading)
                            
                            if images.count > 1 {
                                SliderView(currentIndex: $currentIndex, totalImages: images.count)
                                    .frame(maxWidth: geometry.size.width * 0.8)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.bottom)
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 400, minHeight: 400)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, url.isFileURL {
                        DispatchQueue.main.async {
                            loadImages(from: url)
                        }
                    }
                }
                return true
            }
            return false
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if handleKeyPress(event: event) {
                    return nil
                }
                return event
            }
            startMouseTracking()
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            currentImageURL = images[newValue]
        }
        .onDisappear {
            stopMouseTracking()
        }
    }
    
    private func startMouseTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let window = NSApplication.shared.windows.first {
                // グローバルなマウス位置を取得
                let mouseLocation = NSEvent.mouseLocation
                
                // ウィンドウ内のローカル座標に変換
                let localMouseLocation = window.convertFromScreen(NSRect(origin: mouseLocation, size: .zero)).origin

                // ウィンドウの高さ
                let windowHeight = window.frame.height

                // 画面下部100px以内にマウスがあるかをチェック
                if localMouseLocation.y < 100 {
                    withAnimation {
                        isControlsVisible = true
                    }
                } else {
                    withAnimation {
                        isControlsVisible = false
                    }
                }
            }
        }
    }


    private func stopMouseTracking() {
        timer?.invalidate()
        timer = nil
    }

    // フォルダまたはファイルから全ての画像を読み込む
    func loadImages(from url: URL) {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
        let folderURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        
        print("Debug: 処理を開始するURL: \(url)")
        print("Debug: フォルダURL: \(folderURL)")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            print("Debug: フォルダ内のファイル数: \(files.count)")
            
            self.images = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            print("Debug: フィルタリング後の画像ファイル数: \(self.images.count)")
            
            if !self.images.isEmpty {
                if url.hasDirectoryPath {
                    self.currentIndex = 0
                    print("Debug: フォルダが指定されたため、最初の画像を表示")
                } else {
                    self.currentIndex = self.images.firstIndex(of: url) ?? 0
                    print("Debug: ファイルが指定されたため、そのファイルのインデックスを設定: \(self.currentIndex)")
                }
                self.currentImageURL = self.images[self.currentIndex]
                print("Debug: 現在の画像URL: \(self.currentImageURL?.absoluteString ?? "nil")")
            } else {
                print("Debug: フォルダ内に画像が見つかりませんでした")
            }
        } catch {
            print("Debug: エラーが発生しました: \(error.localizedDescription)")
            handleLoadError(url: url, error: error, imageExtensions: imageExtensions)
        }
        
        print("Debug: 最終的な画像数: \(self.images.count)")
    }
    
    private func handleLoadError(url: URL, error: Error, imageExtensions: [String]) {
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoPermissionError:
                print("Debug: ファイルへのアクセス権限がありません")
                showAlert(message: "ファイルへのアクセス権限がありません。アプリケーションの権限設定を確認してください。")
            case NSFileReadUnknownError:
                print("Debug: ファイルの読み込みに失敗しました")
                showAlert(message: "ファイルの読み込みに失敗しました。ファイルが存在するか確認してください。")
            default:
                print("Debug: 予期せぬエラーが発生しました: \(nsError.localizedDescription)")
                showAlert(message: "予期せぬエラーが発生しました: \(nsError.localizedDescription)")
            }
        }
        
        if imageExtensions.contains(url.pathExtension.lowercased()) {
            self.images = [url]
            self.currentIndex = 0
            self.currentImageURL = url
            print("Debug: エラー発生時、単一のファイルとして処理")
        } else {
            print("Debug: サポートされていないファイル形式です")
            showAlert(message: "サポートされていないファイル形式です")
        }
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "エラー"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // フォルダをダイアログから開いて画像をロード
    private func openFolder() {
        let dialog = NSOpenPanel()
        dialog.title = "フォルダを選択"
        dialog.canChooseFiles = true // ファイルの選択も許可
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
    
    private func toggleFullscreen() {
        isFullscreen.toggle()
        if let window = NSApplication.shared.windows.first {
            if isFullscreen {
                window.toggleFullScreen(nil)
            } else {
                window.toggleFullScreen(nil)
            }
        }
    }
}

struct SliderView: View {
    @Binding var currentIndex: Int
    let totalImages: Int
    
    var body: some View {
        Slider(value: Binding(
            get: { Double(currentIndex) },
            set: { currentIndex = Int($0) }
        ), in: 0...Double(totalImages - 1), step: 1)
    }
}

// メニュー用の構造体
struct ContentView_Menus: Commands {
    @CommandsBuilder var body: some Commands {
        CommandMenu("ファイル") {
            Button("開く...") {
                openFileOrFolder()
            }
            .keyboardShortcut("O", modifiers: .command)
        }
    }
    
    private func openFileOrFolder() {
        let dialog = NSOpenPanel()
        dialog.title = "ファイルまたはフォルダを選択"
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == .OK, let result = dialog.url {
            ContentView().loadImages(from: result)
        }
    }
}
