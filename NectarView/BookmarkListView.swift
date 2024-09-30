import SwiftUI

struct BookmarkListView: View {
    @ObservedObject var imageLoader: ImageLoader
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            HStack {
                Text("ブックマーク")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()

            List {
                ForEach(imageLoader.bookmarks, id: \.self) { index in
                    Button(action: {
                        imageLoader.currentIndex = index
                        isPresented = false
                    }) {
                        HStack {
                            Text("ページ \(index + 1)")
                            Spacer()
                            if let image = imageLoader.getImage(for: imageLoader.images[index]) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}