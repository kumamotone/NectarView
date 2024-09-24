import SwiftUI

struct CustomSliderView: View {
    @Binding var currentIndex: Int
    let totalImages: Int
    let onHover: (Int) -> Void
    let onClick: (Int) -> Void
    
    @State private var hoverLocation: CGFloat = 0
    @State private var isHovering: Bool = false
    
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
                                updateIndex(value: value, in: geometry)
                            }
                            .onEnded { _ in
                                isHovering = false
                                onClick(currentIndex)
                            }
                    )
                
            }
            .overlay(
                Text("\(currentIndex + 1)/\(totalImages)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .opacity(isHovering ? 1 : 0)
                    .position(x: hoverLocation, y: 0)
            )
        }
        .frame(height: 30)
        .contentShape(Rectangle()) // この行を追加
    }
    
    private func updateIndex(value: DragGesture.Value, in geometry: GeometryProxy) {
        let newIndex = Int((value.location.x / geometry.size.width) * CGFloat(totalImages))
        currentIndex = max(0, min(newIndex, totalImages - 1))
        hoverLocation = value.location.x
        isHovering = true
        onHover(currentIndex)
    }
}
