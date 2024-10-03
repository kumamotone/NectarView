import SwiftUI

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
    @State private var hoverPercentage: CGFloat = 0
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

    @State private var isSidebarVisible: Bool = false
    @State private var sidebarWidth: CGFloat = 200
    @State private var isDraggingSidebar: Bool = false

    var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                HStack(spacing: 0) {
                    if isSidebarVisible {
                        ZStack(alignment: .trailing) {
                            SidebarView(imageLoader: imageLoader)
                                .frame(width: sidebarWidth)
                                .transition(.move(edge: .leading))
                            
                            // 見えないリサイズハンドル
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 16)
                                .contentShape(Rectangle())
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.resizeLeftRight.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDraggingSidebar = true
                                            let newWidth = sidebarWidth + value.translation.width
                                            sidebarWidth = max(100, min(newWidth, geometry.size.width / 2))
                                        }
                                        .onEnded { _ in
                                            isDraggingSidebar = false
                                        }
                                )
                        }
                        .frame(width: sidebarWidth)
                    }

                    GeometryReader { geometry in
                        ZStack {
                            appSettings.backgroundColor.edgesIgnoringSafeArea(.all)

                            ImageDisplayView(imageLoader: imageLoader, appSettings: appSettings, geometry: geometry, scale: appSettings.zoomFactor, offset: offset)
                                .rotationEffect(appSettings.isSpreadViewEnabled ? .zero : imageLoader.currentRotation)
                                .scaleEffect(appSettings.zoomFactor)
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
                                        if imageLoader.viewMode != .spreadRightToLeft || (imageLoader.viewMode == .single && appSettings.isLeftRightKeyReversed) {
                                            imageLoader.showPreviousImage()
                                        } else {
                                            imageLoader.showNextImage()
                                        }
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
                                        if imageLoader.viewMode != .spreadRightToLeft || (imageLoader.viewMode == .single && appSettings.isLeftRightKeyReversed) {
                                            imageLoader.showNextImage()
                                        } else {
                                            imageLoader.showPreviousImage()
                                        }
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

                            SliderPreviewView(isSliderHovering: isSliderHovering && isSliderVisible, imageLoader: imageLoader, sliderHoverIndex: sliderHoverIndex, hoverPercentage: hoverPercentage, geometry: geometry)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                VStack {
                    TopControlsView(isVisible: $isTopControlsVisible, appSettings: appSettings, imageLoader: imageLoader, isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll, toggleSidebar: toggleSidebar)

                    Spacer()

                    BottomControlsView(isVisible: $isBottomControlVisible, imageLoader: imageLoader, appSettings: appSettings, geometry: outerGeometry, isControlBarHovered: $isControlBarHovered, sliderHoverIndex: $sliderHoverIndex, hoverPercentage: $hoverPercentage, isSliderHovering: $isSliderHovering, isSliderVisible: $isSliderVisible)
                        .padding(.leading, isSidebarVisible ? sidebarWidth : 0)
                }
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
        .onChange(of: appSettings.zoomFactor) { _, newValue in
            withAnimation(.spring()) {
                self.scale = min(max(newValue, 1.0), 5.0)
                if self.scale == 1.0 {
                    self.offset = .zero
                }
            }
        }
    }

    // マウを定期的に監視
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

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSidebarVisible.toggle()
        }
    }
}

struct SidebarView: View {
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                Button(action: selectFolder) {
                    Image(systemName: "folder")
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 10)
            }
            .frame(height: 48)
            .background(Color.secondary.opacity(0.1))
            
            if !imageLoader.images.isEmpty {
                ScrollViewReader { proxy in
                    List(selection: Binding(
                        get: { imageLoader.currentIndex },
                        set: { imageLoader.currentIndex = $0 }
                    )) {
                        ForEach(Array(imageLoader.images.enumerated()), id: \.element) { index, url in
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                                Text(getDisplayName(for: url, at: index))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .tag(index)
                            .id(index)
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .onChange(of: imageLoader.currentIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("フォルダを選択してください")
                        .foregroundColor(.secondary)
                    Button("選択", action: selectFolder)
                        .padding(.top, 10)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 200)
    }

    private func getDisplayName(for url: URL, at index: Int) -> String {
        if imageLoader.zipFileURL != nil {
            // ZIPファイルの場合
            let entryPath = imageLoader.zipEntryPaths[index]
            let entryComponents = entryPath.split(separator: "|")
            if entryComponents.count > 1 {
                // 書庫内書庫の場合
                return String(entryComponents[1])
            } else {
                return (entryPath as NSString).lastPathComponent
            }
        } else {
            // 通常のファイルの場合
            return url.lastPathComponent
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.folder, .zip]
        
        if panel.runModal() == .OK {
            imageLoader.loadImages(from: panel.url!)
        }
    }
}

struct FileSystemItem: View {
    let url: URL
    @ObservedObject var imageLoader: ImageLoader
    @Binding var expandedPaths: Set<URL>
    @State private var children: [URL]?

    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedPaths.contains(url) },
                set: { newValue in
                    if newValue {
                        expandedPaths.insert(url)
                    } else {
                        expandedPaths.remove(url)
                    }
                }
            ),
            content: {
                if let children = children {
                    ForEach(children, id: \.self) { childURL in
                        if childURL.hasDirectoryPath {
                            FileSystemItem(url: childURL, imageLoader: imageLoader, expandedPaths: $expandedPaths)
                        } else if isImageFile(childURL) {
                            FileItemView(url: childURL, imageLoader: imageLoader)
                        }
                    }
                }
            },
            label: {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                    Text(url.lastPathComponent)
                }
            }
        )
        .onAppear(perform: loadChildren)
    }

    private func loadChildren() {
        DispatchQueue.global(qos: .background).async {
            do {
                let childURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                DispatchQueue.main.async {
                    self.children = childURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
                }
            } catch {
                print("Error loading directory contents: \(error)")
            }
        }
    }

    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

struct FileItemView: View {
    let url: URL
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        HStack {
            Image(systemName: "photo")
                .foregroundColor(.green)
            Text(url.lastPathComponent)
        }
        .onTapGesture {
            imageLoader.loadImages(from: url)
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