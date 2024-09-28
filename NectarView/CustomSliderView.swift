import SwiftUI

struct CustomSliderView: View {
    @Binding var currentIndex: Int
    let totalImages: Int
    let onHover: (Int) -> Void
    let onClick: (Int) -> Void
    @Binding var hoverIndex: Int
    @Binding var hoverLocation: CGFloat
    @Binding var isHovering: Bool
    
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
                    .frame(width: CGFloat(currentIndex + 1) / CGFloat(totalImages) * geometry.size.width, height: 4)
                    .position(x: (CGFloat(currentIndex + 1) / CGFloat(totalImages) * geometry.size.width) / 2, y: geometry.size.height / 2)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: 12, height: 24)
                    .position(x: CGFloat(currentIndex + 1) / CGFloat(totalImages) * geometry.size.width, y: geometry.size.height / 2)
                
                // クリック可能な領域を作成
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(height: 30)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateIndex(location: value.location.x, in: geometry)
                            }
                            .onEnded { value in
                                let newIndex = calculateIndex(for: value.location.x, in: geometry)
                                currentIndex = newIndex
                                isHovering = false
                                onClick(newIndex)
                            }
                    )
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            updateIndex(location: location.x, in: geometry)
                        case .ended:
                            isHovering = false
                        }
                    }
            }
        }
        .frame(height: 30)
        .contentShape(Rectangle())
    }
    
    private func updateIndex(location: CGFloat, in geometry: GeometryProxy) {
        hoverIndex = calculateIndex(for: location, in: geometry)
        hoverLocation = location
        isHovering = true
        onHover(hoverIndex)
    }
    
    private func calculateIndex(for location: CGFloat, in geometry: GeometryProxy) -> Int {
        let newIndex = Int((location / geometry.size.width) * CGFloat(totalImages))
        return max(0, min(newIndex, totalImages - 1))
    }
}
