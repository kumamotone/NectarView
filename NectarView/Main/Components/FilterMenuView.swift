import SwiftUI

struct FilterMenuView: View {
    @ObservedObject var imageLoader: ImageLoader
    
    var body: some View {
        Menu {
            ForEach(ImageFilter.allCases, id: \.self) { filter in
                Button(action: {
                    imageLoader.updateFilter(filter)
                }) {
                    HStack {
                        Text(NSLocalizedString(filter.rawValue, comment: ""))
                        if imageLoader.currentFilter == filter {
                            Image(systemName: "checkmark")
                        }
                        Spacer()
                    }
                }
            }
        } label: {
            Label {
                EmptyView()
            } icon: {
                Image(systemName: "camera.filters")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
    }
}

#Preview {
    FilterMenuView(imageLoader: ImageLoader())
        .background(Color.black.opacity(0.6))
}
