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
                        .onTapGesture(count: 2) {
                            toggleFullscreen()
                        }
                } else {
                    Text("画像を読み込み中...")
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
                        .gesture(
                            DragGesture(coordinateSpace: .global)
                                .onChanged { value in
                                    if !isControlBarDragging {
                                        if dragStartLocation == nil {
                                            dragStartLocation = value.startLocation
                                            windowStartLocation = NSApp.mainWindow?.frame.origin
                                        }
                                        if let startLocation = dragStartLocation,
                                           let windowStart = windowStartLocation,
                                           let window = NSApp.mainWindow {
                                            let dx = value.location.x - startLocation.x
                                            let dy = value.location.y - startLocation.y
                                            window.setFrameOrigin(NSPoint(
                                                x: windowStart.x + dx,
                                                y: windowStart.y + dy
                                            ))
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    dragStartLocation = nil
                                    windowStartLocation = nil
                                }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle()) // ビュー全体をタップ可能にする
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isControlBarDragging {
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
            imageLoader.restoreLastSession()
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if KeyboardHandler.handleKeyPress(event: event, imageLoader: imageLoader) {
                    return nil
                }
                return event
            }
            startMouseTracking()
            imageLoader.prefetchImages()
        }
        .onChange(of: imageLoader.currentIndex) { _ in
            imageLoader.updateLastOpenedIndex()
        }
        .onDisappear {
            stopMouseTracking()
        }
        .navigationTitle(imageLoader.currentTitle)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(appSettings: appSettings)
                .frame(width: 300, height: 150)
        }
    }
    
    private func startMouseTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
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
