import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @State private var images: [URL] = []
    @State private var currentIndex: Int = 0
    @State private var currentImageURL: URL? = nil

    var body: some View {
        VStack {
            if let currentImageURL = currentImageURL {
                WebImage(url: currentImageURL)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Drag and drop a folder or image file here")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Button("Open Folder") {
                openFolder()
            }
            .padding()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, url.isFileURL {
                        DispatchQueue.main.async {
                            loadImages(from: url)
                        }
                    }
                }
                return true
            }
            return false
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyPress(event: event)
                return event
            }
        }
    }
    
    // Load all images from the folder or just one image
    private func loadImages(from url: URL) {
        if url.hasDirectoryPath {
            // If a folder is dropped, load all image files in the folder
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
            do {
                let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                self.images = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                if !self.images.isEmpty {
                    self.currentIndex = 0
                    self.currentImageURL = self.images[self.currentIndex]
                }
            } catch {
                print("Failed to load images from folder: \(error.localizedDescription)")
            }
        } else {
            // If a single image is dropped, load just that image
            self.images = [url]
            self.currentIndex = 0
            self.currentImageURL = url
        }
    }
    
    // Open folder via file dialog
    private func openFolder() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a folder"
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == .OK, let result = dialog.url {
            loadImages(from: result)
        }
    }

    // Handle arrow key presses
    private func handleKeyPress(event: NSEvent) {
        if event.keyCode == 123 { // Left arrow key
            showPreviousImage()
        } else if event.keyCode == 124 { // Right arrow key
            showNextImage()
        }
    }

    // Show the next image
    private func showNextImage() {
        if currentIndex < images.count - 1 {
            currentIndex += 1
            currentImageURL = images[currentIndex]
        }
    }

    // Show the previous image
    private func showPreviousImage() {
        if currentIndex > 0 {
            currentIndex -= 1
            currentImageURL = images[currentIndex]
        }
    }
}
