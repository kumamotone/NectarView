import SwiftUI

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
                                updateCurrentIndex(location: value.location.x, in: geometry)
                            }
                            .onEnded { value in
                                isDragging = false
                                isHovering = false
                                onClick(currentIndex)
                            }
                    )
                    .onHover { hovering in
                        isHovering = hovering && !isDragging
                    }
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            if !isDragging {
                                updateHoverIndex(location: location.x, in: geometry)
                            }
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
    
    private func updateCurrentIndex(location: CGFloat, in geometry: GeometryProxy) {
        currentIndex = calculateIndex(for: location, in: geometry)
        hoverLocation = location
        onHover(currentIndex)
    }
    
    private func calculateIndex(for location: CGFloat, in geometry: GeometryProxy) -> Int {
        let ratio = location / geometry.size.width
        let newIndex = Int(round(ratio * CGFloat(totalImages - 1)))
        return max(0, min(newIndex, totalImages - 1))
    }
}
