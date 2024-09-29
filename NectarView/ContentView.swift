import SwiftUI
import SDWebImageSwiftUI

let dropImagesMessage = NSLocalizedString("DropYourImagesHere", comment: "DropYourImagesHere")

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
    @State private var isTopControlsVisible: Bool = true
    @State private var topControlsTimer: Timer?
    @State private var isInitialDisplay: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appSettings.backgroundColor.edgesIgnoringSafeArea(.all)
                
                ImageDisplayView(imageLoader: imageLoader, appSettings: appSettings, geometry: geometry)
                
                VStack {
                    TopControlsView(isVisible: $isTopControlsVisible, appSettings: appSettings, imageLoader: imageLoader, isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll)

                    Spacer()

                    BottomControlsView(isVisible: $isControlsVisible, imageLoader: imageLoader, appSettings: appSettings, geometry: geometry, isControlBarHovered: $isControlBarHovered, isControlBarDragging: $isControlBarDragging, sliderHoverIndex: $sliderHoverIndex, sliderHoverLocation: $sliderHoverLocation, isSliderHovering: $isSliderHovering)
                }

                SliderPreviewView(isSliderHovering: isSliderHovering, imageLoader: imageLoader, sliderHoverIndex: sliderHoverIndex, sliderHoverLocation: sliderHoverLocation, geometry: geometry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                toggleFullscreen()
            }
            .gesture(createDragGesture())
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(WindowAccessor { window in
            window.isMovableByWindowBackground = false
        })
        .applyContentViewModifiers(appSettings: appSettings, imageLoader: imageLoader, isSettingsPresented: $isSettingsPresented)
        .onAppear {
            setupKeyboardHandler()
            startMouseTracking()
            startTopControlsTimer()
        }
        .onDisappear {
            stopMouseTracking()
            stopAutoScroll()
            stopTopControlsTimer()
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

    private func createDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
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
            .onEnded { _ in
                self.dragOffset = .zero
            }
    }

    private func setupKeyboardHandler() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if KeyboardHandler.handleKeyPress(event: event, imageLoader: imageLoader, appSettings: appSettings) {
                return nil
            }
            return event
        }
    }
}

struct ImageDisplayView: View {
    @ObservedObject var imageLoader: ImageLoader
    @ObservedObject var appSettings: AppSettings
    let geometry: GeometryProxy

    var body: some View {
        Group {
            if appSettings.isSpreadViewEnabled {
                SpreadView(imageLoader: imageLoader, geometry: geometry)
            } else {
                SinglePageView(imageLoader: imageLoader)
            }
        }
    }
}

struct SpreadView: View {
    @ObservedObject var imageLoader: ImageLoader
    let geometry: GeometryProxy

    var body: some View {
        if imageLoader.images.isEmpty {
            Text(dropImagesMessage)
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
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
        }
    }
}

struct SinglePageView: View {
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        Group {
            if let currentImageURL = imageLoader.currentImageURL,
               let image = imageLoader.getImage(for: currentImageURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(dropImagesMessage)
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct TopControlsView: View {
    @Binding var isVisible: Bool
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var imageLoader: ImageLoader
    @Binding var isAutoScrolling: Bool
    @Binding var autoScrollInterval: Double
    let toggleAutoScroll: () -> Void

    var body: some View {
        if isVisible {
            HStack(spacing: 15) {
                Spacer()
                AutoScrollControls(isAutoScrolling: $isAutoScrolling, autoScrollInterval: $autoScrollInterval, toggleAutoScroll: toggleAutoScroll)
                ViewModeButton(appSettings: appSettings)
                ReadingDirectionButton(appSettings: appSettings)
            }
            .padding(.top, 10)
            .padding(.trailing, 10)
            .transition(.move(edge: .top))
        }
    }
}

struct AutoScrollControls: View {
    @Binding var isAutoScrolling: Bool
    @Binding var autoScrollInterval: Double
    let toggleAutoScroll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggleAutoScroll) {
                Image(systemName: isAutoScrolling ? "pause.fill" : "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())
            .instantTooltip(isAutoScrolling ? "自動ページめくりを停止" : "自動ページめくりを開始")

            Slider(value: $autoScrollInterval, in: 0.5...30.0, step: 0.5)
                .frame(width: 80)
                .accentColor(.white)
                .instantTooltip("自動ページめくりの間隔を設定（0.5秒〜30秒）")
            Text(String(format: "%.1f秒", autoScrollInterval))
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
        .instantTooltip("自動ページめくりの設定")
    }
}

struct ViewModeButton: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Button(action: {
            appSettings.isSpreadViewEnabled.toggle()
        }) {
            Image(systemName: appSettings.isSpreadViewEnabled ? "book.fill" : "doc.text.fill")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip("単ページ/見開き")
    }
}

struct ReadingDirectionButton: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Button(action: {
            appSettings.isRightToLeftReading.toggle()
        }) {
            Image(systemName: appSettings.isRightToLeftReading ? "arrow.left" : "arrow.right")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(TopControlButtonStyle())
        .instantTooltip("方向")
    }
}

struct BottomControlsView: View {
    @Binding var isVisible: Bool
    @ObservedObject var imageLoader: ImageLoader
    @ObservedObject var appSettings: AppSettings
    let geometry: GeometryProxy
    @Binding var isControlBarHovered: Bool
    @Binding var isControlBarDragging: Bool
    @Binding var sliderHoverIndex: Int
    @Binding var sliderHoverLocation: CGFloat
    @Binding var isSliderHovering: Bool

    var body: some View {
        if isVisible && !imageLoader.images.isEmpty {
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
}

struct SliderPreviewView: View {
    let isSliderHovering: Bool
    @ObservedObject var imageLoader: ImageLoader
    let sliderHoverIndex: Int
    let sliderHoverLocation: CGFloat
    let geometry: GeometryProxy

    var body: some View {
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
}

extension View {
    func applyContentViewModifiers(appSettings: AppSettings, imageLoader: ImageLoader, isSettingsPresented: Binding<Bool>) -> some View {
        self
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
    }
}

struct TopControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
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