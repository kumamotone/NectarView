import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    // MARK: - Observed Objects
    @ObservedObject var imageLoader: ImageLoader
    @EnvironmentObject var appSettings: AppSettings

    // MARK: - State Properties
    // 一定時間後に自動的に画面上部のコントロールを隠す機能
    @State private var isTopControlsVisible: Bool = true
    @State private var topControlsTimer: Timer?
    @State private var isInitialDisplay: Bool = true

    // 自動めくり用の機能
    @State private var isAutoScrolling: Bool = false
    @State private var autoScrollInterval: Double = 3.0
    @State private var autoScrollTimer: Timer?

    // 画面下部のコントロール絡みのState
    @State private var isBottomControlVisible: Bool = false
    @State private var isControlBarHovered: Bool = false
    @State private var sliderHoverIndex: Int = 0
    @State private var sliderHoverLocation: CGFloat = 0
    @State private var isSliderHovering: Bool = false
    @State private var isSliderVisible: Bool = false

    // マウスで左右切り替え用のコントロール
    @State private var isLeftCursorHovered: Bool = false
    @State private var isRightCursorHovered: Bool = false

    // 拡大縮小と表示位置
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero

    // ドラッグでウィンドウ位置の調整
    @State private var dragOffset: CGSize = .zero

    // ドラッグ中かどうか
    @State private var isDraggingImage: Bool = false

    // モーダルの表示非表示
    @State private var isSettingsPresented: Bool = false
    @State private var isBookmarkListPresented: Bool = false

    // マウスを定期的に監視 なんでもいい
    @State private var mouseTrackingTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appSettings.backgroundColor.edgesIgnoringSafeArea(.all)

                ImageDisplayView(imageLoader: imageLoader, appSettings: appSettings, geometry: geometry, scale: scale, offset: offset)
                    .rotationEffect(appSettings.isSpreadViewEnabled ? .zero : imageLoader.currentRotation)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if self.scale > 1.0 && self.isImageDraggable(in: geometry.size) {
                                    if !self.isDraggingImage {
                                        self.isDraggingImage = true
                                        self.dragStartOffset = self.offset
                                    }
                                    let translation = CGSize(
                                        width: value.translation.width + self.dragStartOffset.width,
                                        height: value.translation.height + self.dragStartOffset.height
                                    )
                                    self.offset = limitOffset(translation, in: geometry.size)
                                } else {
                                    self.handleWindowDrag(value)
                                }
                            }
                            .onEnded { _ in
                                self.isDraggingImage = false
                                self.dragOffset = .zero
                            }
                    )

                HStack(spacing: 0) {
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(isLeftCursorHovered ? 0.2 : 0), Color.clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.15)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            imageLoader.showPreviousImage()
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLeftCursorHovered = hovering
                            }
                        }
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .opacity(isLeftCursorHovered ? 0.6 : 0)
                                .padding(.leading, 5)
                        )
                    Spacer()
                    LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(isRightCursorHovered ? 0.2 : 0)]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.15)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            imageLoader.showNextImage()
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRightCursorHovered = hovering
                            }
                        }
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .opacity(isRightCursorHovered ? 0.6 : 0)
                                .padding(.trailing, 5)
                        )
                }

                VStack {
                    TopControlsView(isVisible: $isTopControlsVisible, appSettings: appSettings, imageLoader: imageLoader, isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll)

                    Spacer()

                    BottomControlsView(isVisible: $isBottomControlVisible, imageLoader: imageLoader, appSettings: appSettings, geometry: geometry, isControlBarHovered: $isControlBarHovered, sliderHoverIndex: $sliderHoverIndex, sliderHoverLocation: $sliderHoverLocation, isSliderHovering: $isSliderHovering, isSliderVisible: $isSliderVisible)
                }

                SliderPreviewView(isSliderHovering: isSliderHovering && isSliderVisible, imageLoader: imageLoader, sliderHoverIndex: sliderHoverIndex, sliderHoverLocation: sliderHoverLocation, geometry: geometry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.handleWindowDrag(value)
                    }
                    .onEnded { _ in
                        self.dragOffset = .zero
                    }
            )
            .onTapGesture(count: 2) {
                toggleFullscreen()
            }
            .contextMenu {
                ContextMenuContent(
                    imageLoader: imageLoader,
                    isSettingsPresented: $isSettingsPresented,
                    isBookmarkListPresented: $isBookmarkListPresented
                )
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(WindowAccessor { window in
            window.isMovableByWindowBackground = false
        })
        .applyContentViewModifiers(appSettings: appSettings, imageLoader: imageLoader)
        .onAppear {
            KeyboardHandler.setupKeyboardHandler(for: self)
            startMouseTracking()
            startTopControlsTimer()
        }
        .onDisappear {
            stopMouseTracking()
            stopAutoScroll()
            stopTopControlsTimer()
        }
        .navigationTitle(imageLoader.currentImageInfo)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(appSettings: appSettings)
        }
        .sheet(isPresented: $isBookmarkListPresented) {
            BookmarkListView(imageLoader: imageLoader, isPresented: $isBookmarkListPresented)
        }
    }

    // マウスを定期的に監視
    private func startMouseTracking() {
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.16, repeats: true) { _ in
            if let window = NSApplication.shared.windows.first {
                let mouseLocation = NSEvent.mouseLocation
                let windowFrame = window.frame

                if windowFrame.contains(mouseLocation) {
                    let localMouseLocation = window.convertFromScreen(NSRect(origin: mouseLocation, size: .zero)).origin

                    withAnimation {
                        isBottomControlVisible = localMouseLocation.y < 100
                        if !isInitialDisplay {
                            isTopControlsVisible = localMouseLocation.y > windowFrame.size.height - 100
                        }
                    }
                } else {
                    withAnimation {
                        isBottomControlVisible = false
                        if !isInitialDisplay {
                            isTopControlsVisible = false
                        }
                    }
                }
            }
        }
    }

    // マウスの監視を停止
    private func stopMouseTracking() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
    }

    // フルスクリーンの切り替え
    private func toggleFullscreen() {
        if let window = NSApplication.shared.windows.first {
            window.toggleFullScreen(nil)
        }
    }

    // 自動ページめくりの切り替え
    private func toggleAutoScroll() {
        if isAutoScrolling {
            stopAutoScroll()
        } else {
            startAutoScroll()
        }
    }

    // 自動ページめくりの開始
    private func startAutoScroll() {
        isAutoScrolling = true
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { _ in
            imageLoader.showNextImage()
        }
    }

    // 自動ページめくりの停止
    private func stopAutoScroll() {
        isAutoScrolling = false
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    // 上部のコントロールのタイマーの開始
    private func startTopControlsTimer() {
        isTopControlsVisible = true
        isInitialDisplay = true
        topControlsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation {
                self.isTopControlsVisible = false
                self.isInitialDisplay = false
            }
        }
    }

    // 上部のコントロールのタイマーの停止
    private func stopTopControlsTimer() {
        topControlsTimer?.invalidate()
        topControlsTimer = nil
    }

    // MARK: - Zoom Functions
    func zoom(by factor: CGFloat) {
        withAnimation(.spring()) {
            let newScale = self.scale * factor
            self.scale = min(max(newScale, 1.0), 5.0)
            if self.scale == 1.0 {
                self.offset = .zero
            }
        }
    }

    // 拡大縮小の変更
    func zoom(to newScale: CGFloat) {
        withAnimation(.spring()) {
            self.scale = min(max(newScale, 1.0), 5.0)
            if self.scale == 1.0 {
                self.offset = .zero
            }
        }
    }

    // 拡大縮小のリセット
    func resetZoom() {
        withAnimation(.spring()) {
            self.scale = 1.0
            self.offset = .zero
        }
    }

    // MARK: - Offset and Dragging Functions
    private func limitOffset(_ offset: CGSize, in size: CGSize) -> CGSize {
        let maxOffsetX = max(0, (size.width * scale - size.width) / 2)
        let maxOffsetY = max(0, (size.height * scale - size.height) / 2)

        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }

    // 画像のドラッグの可否
    private func isImageDraggable(in size: CGSize) -> Bool {
        let scaledWidth = size.width * scale
        let scaledHeight = size.height * scale
        return scaledWidth > size.width + 1 || scaledHeight > size.height + 1
    }

    // ウィンドウのドラッグ
    private func handleWindowDrag(_ value: DragGesture.Value) {
        if !isControlBarHovered && !isTopControlsVisible {
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
}

extension View {
    func applyContentViewModifiers(appSettings: AppSettings, imageLoader: ImageLoader) -> some View {
        self
            .onChange(of: appSettings.isSpreadViewEnabled) { _, _ in
                imageLoader.updateCurrentImage()
            }
            .onChange(of: appSettings.isRightToLeftReading) { _, _ in
                imageLoader.updateCurrentImage()
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                if let provider = providers.first {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
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
    }
}
