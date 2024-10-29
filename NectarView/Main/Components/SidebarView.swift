import SwiftUI

struct SidebarView: View {
    @ObservedObject var imageLoader: ImageLoader

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                Button(action: selectFolder) {
                    Image(systemName: "folder")
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 10)
            }
            .frame(height: 48)
            .background(Color.secondary.opacity(0.1))

            if !imageLoader.images.isEmpty {
                ScrollViewReader { proxy in
                    List(selection: Binding(
                        get: { imageLoader.currentIndex },
                        set: { imageLoader.currentIndex = $0 }
                    )) {
                        ForEach(Array(imageLoader.images.enumerated()), id: \.element) { index, url in
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                                Text(imageLoader.getDisplayName(for: url, at: index))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .tag(index)
                            .id(index)
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .onChange(of: imageLoader.currentIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("Please select a folder", comment: ""))
                        .foregroundColor(.secondary)
                    Button(NSLocalizedString("Select", comment: "")) {
                        selectFolder()
                    }
                        .padding(.top, 10)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 200)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.folder, .zip]

        if panel.runModal() == .OK {
            imageLoader.loadImages(from: panel.url!)
        }
    }
} 