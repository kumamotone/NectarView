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
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(currentIndex + 1) / CGFloat(totalImages) * geometry.size.width, height: 4)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 16, height: 16)
                    .position(x: CGFloat(currentIndex + 1) / CGFloat(totalImages) * geometry.size.width, y: 2)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newIndex = Int((value.location.x / geometry.size.width) * CGFloat(totalImages))
                        currentIndex = max(0, min(newIndex, totalImages - 1))
                        hoverLocation = value.location.x
                        isHovering = true
                        onHover(currentIndex)
                    }
                    .onEnded { _ in
                        isHovering = false
                        onClick(currentIndex)
                    }
            )
            .overlay(
                Text("\(currentIndex + 1)/\(totalImages)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .opacity(isHovering ? 1 : 0)
                    .position(x: hoverLocation, y: -20)
            )
        }
        .frame(height: 20)
    }
}