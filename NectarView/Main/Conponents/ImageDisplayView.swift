import SwiftUI

private struct SizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func captureSize(in binding: Binding<CGSize>) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: SizeKey.self, value: proxy.size)
        })
            .onPreferenceChange(SizeKey.self) { size in binding.wrappedValue = size }
    }
}

struct Rotated<Rotated: View>: View {
    var view: Rotated
    var angle: Angle

    init(_ view: Rotated, angle: Angle = .degrees(-90)) {
        self.view = view
        self.angle = angle
    }

    @State private var size: CGSize = .zero

    var body: some View {
        // Rotate the frame, and compute the smallest integral frame that contains it
        let newFrame = CGRect(origin: .zero, size: size)
            .offsetBy(dx: -size.width/2, dy: -size.height/2)
            .applying(.init(rotationAngle: CGFloat(angle.radians)))
            .integral

        return view
            .fixedSize()                    // Don't change the view's ideal frame
            .captureSize(in: $size)         // Capture the size of the view's ideal frame
            .rotationEffect(angle)          // Rotate the view
            .frame(width: newFrame.width,   // And apply the new frame
                   height: newFrame.height)
    }
}

extension View {
    func rotated(_ angle: Angle = .degrees(-90)) -> some View {
        Rotated(self, angle: angle)
    }
}

// 画像表示領域
// 設定によって、単一ページと見開きページが切り替わる
struct ImageDisplayView: View {
    @ObservedObject var imageLoader: ImageLoader
    @ObservedObject var appSettings: AppSettings
    let geometry: GeometryProxy
    let scale: CGFloat
    let offset: CGSize

    var body: some View {
        Group {
            if appSettings.isSpreadViewEnabled {
                SpreadView(imageLoader: imageLoader, geometry: geometry, scale: scale, offset: offset)
            } else {
                SinglePageView(imageLoader: imageLoader, scale: scale, offset: offset)
            }
        }
    }
}
// 単一ページ
struct SinglePageView: View {
    @ObservedObject var imageLoader: ImageLoader
    let scale: CGFloat
    let offset: CGSize

    var body: some View {
        Group {
            if let currentImageIndex = imageLoader.currentImages.0,
               let image = imageLoader.getImage(for: imageLoader.images[currentImageIndex]) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(NSLocalizedString("DropYourImagesHere", comment: "DropYourImagesHere"))
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// 見開きページ
struct SpreadView: View {
    @ObservedObject var imageLoader: ImageLoader
    let geometry: GeometryProxy
    let scale: CGFloat
    let offset: CGSize

    var body: some View {
        if imageLoader.images.isEmpty {
            Text(NSLocalizedString("DropYourImagesHere", comment: "DropYourImagesHere"))
                .font(.headline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ForEach([imageLoader.currentImages.0, imageLoader.currentImages.1].compactMap { $0 }, id: \.self) { index in
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
