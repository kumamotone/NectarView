import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @ObservedObject var imageLoader: ImageLoader
    @EnvironmentObject var appSettings: AppSettings
    @State private var isControlsVisible: Bool = false
    @State private var timer: Timer?
    @State var isSettingsPresented: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var isControlBarDragging: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var isControlBarHovered: Bool = false
    @State private var sliderHoverIndex: Int = 0
    @State private var sliderHoverLocation: CGFloat = 0
    @State private var isSliderHovering: Bool = false
    @State private var isAutoScrolling: Bool = false
    @State private var autoScrollInterval: Double = 3.0
    @State private var autoScrollTimer: Timer?
    @State private var isTopControlsVisible: Bool = true
    @State private var topControlsTimer: Timer?
    @State private var isInitialDisplay: Bool = true
    @State private var isLeftHovered: Bool = false
    @State private var isRightHovered: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    @State private var isDraggingImage: Bool = false
    @State private var isBookmarkListPresented: Bool = false
    @State private var isSliderVisible: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appSettings.backgroundColor.edgesIgnoringSafeArea(.all)
                
                ImageDisplayView(imageLoader: imageLoader, appSettings: appSettings, geometry: geometry, scale: scale, offset: offset)
                    .rotationEffect(imageLoader.currentRotation)
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
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(isLeftHovered ? 0.2 : 0), Color.clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.15)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if appSettings.isSpreadViewEnabled {
                                imageLoader.showPreviousSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
                            } else {
                                imageLoader.showPreviousImage()
                            }
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLeftHovered = hovering
                            }
                        }
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .opacity(isLeftHovered ? 0.6 : 0)
                                .padding(.leading, 5)
                        )
                    Spacer()
                    LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(isRightHovered ? 0.2 : 0)]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.15)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if appSettings.isSpreadViewEnabled {
                                imageLoader.showNextSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
                            } else {
                                imageLoader.showNextImage()
                            }
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRightHovered = hovering
                            }
                        }
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .opacity(isRightHovered ? 0.6 : 0)
                                .padding(.trailing, 5)
                        )
                }
                
                VStack {
                    TopControlsView(isVisible: $isTopControlsVisible, appSettings: appSettings, imageLoader: imageLoader, isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll)

                    Spacer()

                    BottomControlsView(isVisible: $isControlsVisible, imageLoader: imageLoader, appSettings: appSettings, geometry: geometry, isControlBarHovered: $isControlBarHovered, isControlBarDragging: $isControlBarDragging, sliderHoverIndex: $sliderHoverIndex, sliderHoverLocation: $sliderHoverLocation, isSliderHovering: $isSliderHovering, isSliderVisible: $isSliderVisible)
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
        .applyContentViewModifiers(appSettings: appSettings, imageLoader: imageLoader, isSettingsPresented: $isSettingsPresented)
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
                let mouseLocation = NSEvent.mouseLocation
                let windowFrame = window.frame
                
                if NSPointInRect(mouseLocation, windowFrame) {
                    let localMouseLocation = window.convertFromScreen(NSRect(origin: mouseLocation, size: .zero)).origin

                    withAnimation {
                        isControlsVisible = localMouseLocation.y < 100
                        if !isInitialDisplay {
                            isTopControlsVisible = localMouseLocation.y > windowFrame.size.height - 100
                        }
                    }
                } else {
                    withAnimation {
                        isControlsVisible = false
                        if !isInitialDisplay {
                            isTopControlsVisible = false
                        }
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

    private func stopTopControlsTimer() {
        topControlsTimer?.invalidate()
        topControlsTimer = nil
    }

    func zoom(by factor: CGFloat) {
        withAnimation(.spring()) {
            let newScale = self.scale * factor
            self.scale = min(max(newScale, 1.0), 5.0)
            if self.scale == 1.0 {
                self.offset = .zero
            }
        }
    }

    func zoom(to newScale: CGFloat) {
        withAnimation(.spring()) {
            self.scale = min(max(newScale, 1.0), 5.0)
            if self.scale == 1.0 {
                self.offset = .zero
            }
        }
    }

    func resetZoom() {
        withAnimation(.spring()) {
            self.scale = 1.0
            self.offset = .zero
        }
    }

    private func limitOffset(_ offset: CGSize, in size: CGSize) -> CGSize {
        let maxOffsetX = max(0, (size.width * scale - size.width) / 2)
        let maxOffsetY = max(0, (size.height * scale - size.height) / 2)
        
        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }

    private func isImageDraggable(in size: CGSize) -> Bool {
        let scaledWidth = size.width * scale
        let scaledHeight = size.height * scale
        return scaledWidth > size.width + 1 || scaledHeight > size.height + 1
    }

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
    func applyContentViewModifiers(appSettings: AppSettings, imageLoader: ImageLoader, isSettingsPresented: Binding<Bool>) -> some View {
        self
            .onChange(of: appSettings.isSpreadViewEnabled) { _, _ in
                imageLoader.updateSpreadIndices(isSpreadViewEnabled: appSettings.isSpreadViewEnabled, isRightToLeftReading: appSettings.isRightToLeftReading)
            }
            .onChange(of: appSettings.isRightToLeftReading) { _, _ in
                imageLoader.updateSpreadIndices(isSpreadViewEnabled: appSettings.isSpreadViewEnabled, isRightToLeftReading: appSettings.isRightToLeftReading)
            }
            .onChange(of: imageLoader.currentIndex) { _, _ in
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
    }
}
