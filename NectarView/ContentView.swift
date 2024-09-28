import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject private var imageLoader = ImageLoader()
    @EnvironmentObject private var appSettings: AppSettings
    @State private var isControlsVisible: Bool = false
    @State private var timer: Timer?
    @State private var isFullscreen: Bool = false
    @State var isSettingsPresented: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var isDragging: Bool = false
    @State private var isControlBarDragging: Bool = false
    @State private var dragStartLocation: NSPoint?
    @State private var windowStartLocation: NSPoint?
    @State private var dragOffset: CGSize = .zero
    @State private var isControlBarHovered: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appSettings.backgroundColor.edgesIgnoringSafeArea(.all)
                
                if let currentImageURL = imageLoader.currentImageURL,
                   let image = imageLoader.getImage(for: currentImageURL) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text(NSLocalizedString("DropYourImagesHere", comment: "DropYourImagesHere"))
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Spacer()
                    if isControlsVisible && !imageLoader.images.isEmpty {
                        HStack {
                            Text("\(imageLoader.currentIndex + 1) / \(imageLoader.images.count)")
                                .font(.caption)
                                .padding(.leading)
                            
                            if imageLoader.images.count > 1 {
                                CustomSliderView(
                                    currentIndex: $imageLoader.currentIndex,
                                    totalImages: imageLoader.images.count,
                                    onHover: { index in
                                        // ホバー時の処理（必要に応じて）
                                    },
                                    onClick: { index in
                                        imageLoader.currentIndex = index
                                        imageLoader.prefetchImages()
                                    }
                                )
                                .frame(maxWidth: geometry.size.width * 0.8)
                            }
                        }
                        .padding()
                        .background(appSettings.controlBarColor)
                        .cornerRadius(10)
                        .padding(.bottom)
                        .transition(.move(edge: .bottom))
                        .onHover { hovering in
                            isControlBarHovered = hovering
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { _ in
                                    isControlBarDragging = true
                                }
                                .onEnded { _ in
                                    isControlBarDragging = false
                                }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle()) // ビュー全体をタップ可能にする
            .onTapGesture(count: 2) {
                toggleFullscreen()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isControlBarHovered {
                            let newDragOffset = CGSize(
                                width: value.translation.width + self.dragOffset.width,
                                height: value.translation.height + self.dragOffset.height
                            )
                            if let window = NSApp.mainWindow {
                                window.setFrameOrigin(NSPoint(
                                    x: window.frame.origin.x + newDragOffset.width - self.dragOffset.width,
                                    y: window.frame.origin.y - newDragOffset.height + self.dragOffset.height
                                ))
                            }
                            self.dragOffset = newDragOffset
                        }
                    }
                    .onEnded { _ in
                        self.dragOffset = .zero
                    }
            )
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(WindowAccessor { window in
            window.isMovableByWindowBackground = false
        })
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, url.isFileURL {
                        DispatchQueue.main.async {
                            imageLoader.loadImages(from: url)
                        }
                    }
                }
                return true
            }
            return false
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if KeyboardHandler.handleKeyPress(event: event, imageLoader: imageLoader, appSettings: appSettings) {
                    return nil
                }
                return event
            }
            startMouseTracking()
        }
        .onDisappear {
            stopMouseTracking()
        }
        .navigationTitle(currentImageInfo)
        .onChange(of: imageLoader.currentIndex) { _, _ in
            updateWindowTitle()
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(appSettings: appSettings)
                .frame(width: 300, height: 150)
        }
    }

    private var currentImageInfo: String {
        if imageLoader.images.isEmpty {
            return NSLocalizedString("NoImagesLoaded", comment: "画像がロードされていません")
        } else {
            let folderInfo = imageLoader.currentFolderPath
            let fileInfo = imageLoader.currentFileName
            return "\(folderInfo)/\(fileInfo) (\(imageLoader.currentIndex + 1)/\(imageLoader.images.count))"
        }
    }

    private func updateWindowTitle() {
        if let window = NSApplication.shared.windows.first {
            window.title = currentImageInfo
        }
    }

    private func startMouseTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let window = NSApplication.shared.windows.first {
                // グローバルなマウス位置を取得
                let mouseLocation = NSEvent.mouseLocation
                
                // ウィンドウの位置とサイズを取得
                let windowFrame = window.frame
                
                // マウスがウィンドウ内にあるかチェック
                if NSPointInRect(mouseLocation, windowFrame) {
                    // ウィンドウ内のローカル座標に変換
                    let localMouseLocation = window.convertFromScreen(NSRect(origin: mouseLocation, size: .zero)).origin

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
                } else {
                    // マウスがウィンドウ外にある場合はコントロールを非表示にする
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

    private func toggleFullscreen() {
        if let window = NSApplication.shared.windows.first {
            window.toggleFullScreen(nil)
        }
    }
}

// WindowAccessorを追加
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
