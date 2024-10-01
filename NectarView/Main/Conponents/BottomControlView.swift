import SwiftUI

// 下部のコントロール
struct BottomControlsView: View {
    @Binding var isVisible: Bool
    @ObservedObject var imageLoader: ImageLoader
    @ObservedObject var appSettings: AppSettings
    let geometry: GeometryProxy
    @Binding var isControlBarHovered: Bool
    @Binding var sliderHoverIndex: Int
    @Binding var sliderHoverLocation: CGFloat
    @Binding var isSliderHovering: Bool
    @Binding var isSliderVisible: Bool

    var body: some View {
        if isVisible && !imageLoader.images.isEmpty {
            HStack {
                Text("\(imageLoader.currentIndex + 1) / \(imageLoader.images.count)")
                    .font(.caption)
                    .padding(.leading, 10)
                    .foregroundColor(.white)
                
                if imageLoader.images.count > 1 {
                    CustomSliderView(
                        currentIndex: $imageLoader.currentIndex,
                        totalImages: imageLoader.images.count,
                        onHover: { index in
                        },
                        onClick: { index in
                            imageLoader.updateSafeCurrentIndex(index)
                        },
                        hoverIndex: $sliderHoverIndex,
                        hoverLocation: $sliderHoverLocation,
                        isHovering: $isSliderHovering
                    )
                    .frame(maxWidth: geometry.size.width * 0.8)
                    .padding(.horizontal, 10)
                    .onAppear { isSliderVisible = true }
                    .onDisappear { isSliderVisible = false }
                }
            }
            .padding(.vertical, 8)
            .background(appSettings.controlBarColor)
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .onHover { hovering in
                isControlBarHovered = hovering
            }
        }
    }
}

// 画像選択スライダー
struct CustomSliderView: View {
    @Binding var currentIndex: Int
    let totalImages: Int
    let onHover: (Int) -> Void
    let onClick: (Int) -> Void
    @Binding var hoverIndex: Int
    @Binding var hoverLocation: CGFloat
    @Binding var isHovering: Bool
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 実際のスライダーの外観
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(currentIndex) / CGFloat(totalImages - 1) * geometry.size.width, height: 4)
                    .position(x: (CGFloat(currentIndex) / CGFloat(totalImages - 1) * geometry.size.width) / 2, y: geometry.size.height / 2)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: 12, height: 24)
                    .position(x: CGFloat(currentIndex) / CGFloat(totalImages - 1) * geometry.size.width, y: geometry.size.height / 2)
                
                // クリック可能な領域を作成
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(height: 30)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                updateIndexAndHover(location: value.location.x, in: geometry)
                            }
                            .onEnded { value in
                                isDragging = false
                                onClick(currentIndex)
                            }
                    )
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            updateHoverIndex(location: location.x, in: geometry)
                        case .ended:
                            isHovering = false
                        }
                    }
            }
        }
        .frame(height: 30)
        .contentShape(Rectangle())
    }
    
    private func updateHoverIndex(location: CGFloat, in geometry: GeometryProxy) {
        hoverIndex = calculateIndex(for: location, in: geometry)
        hoverLocation = location
        isHovering = true
        onHover(hoverIndex)
    }
    
    private func updateIndexAndHover(location: CGFloat, in geometry: GeometryProxy) {
        let newIndex = calculateIndex(for: location, in: geometry)
        currentIndex = newIndex
        hoverIndex = newIndex
        hoverLocation = location
        isHovering = true
        onHover(newIndex)
    }
    
    private func calculateIndex(for location: CGFloat, in geometry: GeometryProxy) -> Int {
        let ratio = location / geometry.size.width
        let newIndex = Int(round(ratio * CGFloat(totalImages - 1)))
        return max(0, min(newIndex, totalImages - 1))
    }
}
