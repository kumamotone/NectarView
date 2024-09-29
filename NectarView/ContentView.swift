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
    @State private var sliderHoverIndex: Int = 0
    @State private var sliderHoverLocation: CGFloat = 0
    @State private var isSliderHovering: Bool = false
    @State private var isAutoScrolling: Bool = false
    @State private var autoScrollInterval: Double = 3.0
    @State private var autoScrollTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appSettings.backgroundColor.edgesIgnoringSafeArea(.all)
                
                if appSettings.isSpreadViewEnabled {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        ForEach([imageLoader.currentSpreadIndices.0, imageLoader.currentSpreadIndices.1].compactMap { $0 }, id: \.self) { index in
                            if index < imageLoader.images.count,
                               let image = imageLoader.getImage(for: imageLoader.images[index]) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: min(geometry.size.width / 2, geometry.size.height * (image.size.width / image.size.height)), maxHeight: geometry.size.height)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                } else {
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
                }
                
                VStack {
                    HStack {
                        Spacer()
                        // 自動ページめくりコントロール
                        HStack {
                            Button(action: toggleAutoScroll) {
                                Image(systemName: isAutoScrolling ? "pause.circle" : "play.circle")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Slider(value: $autoScrollInterval, in: 0.5...10.0, step: 0.1)
                                .frame(width: 100)
                            Text(String(format: "%.1f秒", autoScrollInterval))
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)

                        Button(action: {
                            appSettings.isSpreadViewEnabled.toggle()
                        }) {
                            Image(systemName: appSettings.isSpreadViewEnabled ? "book.closed" : "book.open")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        }
                        Button(action: {
                            appSettings.isRightToLeftReading.toggle()
                        }) {
                            Image(systemName: appSettings.isRightToLeftReading ? "arrow.left" : "arrow.right")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)

                    Spacer()

                    if isControlsVisible && !imageLoader.images.isEmpty {
                        HStack {
                            Text("\(imageLoader.currentIndex + 1) / \(imageLoader.images.count)")
                                .font(.caption)
                                .padding(.leading, 10)
                            
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
                                    },
                                    hoverIndex: $sliderHoverIndex,
                                    hoverLocation: $sliderHoverLocation,
                                    isHovering: $isSliderHovering
                                )
                                .frame(maxWidth: geometry.size.width * 0.8)
                                .padding(.horizontal, 10)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(appSettings.controlBarColor)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
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

                // プレビュー表示
                if isSliderHovering, let previewImage = imageLoader.getImage(for: imageLoader.images[sliderHoverIndex]) {
                    VStack {
                        Image(nsImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .cornerRadius(10)
                        Text("\(sliderHoverIndex + 1)/\(imageLoader.images.count)")
                            .font(.caption)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .position(x: sliderHoverLocation + 100, y: geometry.size.height - 200)
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
        .onChange(of: appSettings.isSpreadViewEnabled) { _ in
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: appSettings.isSpreadViewEnabled, isRightToLeftReading: appSettings.isRightToLeftReading)
        }
        .onChange(of: appSettings.isRightToLeftReading) { _ in
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: appSettings.isSpreadViewEnabled, isRightToLeftReading: appSettings.isRightToLeftReading)
        }
        .onChange(of: imageLoader.currentIndex) { _ in
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: appSettings.isSpreadViewEnabled, isRightToLeftReading: appSettings.isRightToLeftReading)
        }
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
            stopAutoScroll()
        }
        .navigationTitle(currentImageInfo)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(appSettings: appSettings)
                .frame(width: 300, height: 150)
        }
    }

    private var currentImageInfo: String {
        if let zipFileName = imageLoader.currentZipFileName {
            if let entryFileName = imageLoader.currentZipEntryFileName {
                return "\(zipFileName) - \(entryFileName) (\(imageLoader.currentIndex + 1)/\(imageLoader.images.count))"
            } else {
                return "\(zipFileName) (\(imageLoader.currentIndex + 1)/\(imageLoader.images.count))"
            }
        } else if imageLoader.images.isEmpty {
            return NSLocalizedString("NoImagesLoaded", comment: "画像がロードされていません")
        } else {
            let folderInfo = imageLoader.currentFolderPath
            let fileInfo = imageLoader.currentFileName
            return "\(folderInfo)/\(fileInfo) (\(imageLoader.currentIndex + 1)/\(imageLoader.images.count))"
        }
    }

    private func startMouseTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let window = NSApplication.shared.windows.first {
                // グローバルなマウス位置を取
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
                    // マウスがウィンドウ外にある場合はコントロールを非表示にす
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

    private func toggleAutoScroll() {
        if isAutoScrolling {
            stopAutoScroll()
        } else {
            startAutoScroll()
        }
    }

    private func startAutoScroll() {
        isAutoScrolling = true
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { _ in
            if appSettings.isSpreadViewEnabled {
                imageLoader.showNextSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
            } else {
                imageLoader.showNextImage()
            }
        }
    }

    private func stopAutoScroll() {
        isAutoScrolling = false
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
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