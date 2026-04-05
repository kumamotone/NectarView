import SwiftUI

// スライダーの上にマウスを置いたときに、その画像を表示するための領域
struct SliderPreviewView: View {
    let isSliderHovering: Bool
    @ObservedObject var imageLoader: ImageLoader
    let sliderHoverIndex: Int
    let hoverPercentage: CGFloat
    let geometry: GeometryProxy

    var body: some View {
        if isSliderHovering,
           sliderHoverIndex >= 0 && sliderHoverIndex < imageLoader.images.count,
           let previewImage = imageLoader.getImage(for: imageLoader.images[sliderHoverIndex]) {
            VStack {
                Image(nsImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                    .cornerRadius(10)
                Text("\(sliderHoverIndex + 1) / \(imageLoader.images.count)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .position(x: geometry.size.width / 2, y: geometry.size.height - geometry.size.height * 0.3)
        }
    }
}
