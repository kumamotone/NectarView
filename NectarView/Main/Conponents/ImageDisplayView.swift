import SwiftUI

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
