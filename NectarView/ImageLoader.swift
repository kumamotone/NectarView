import Foundation
import AppKit
import ZIPFoundation
import SDWebImage

class ImageLoader: ObservableObject {
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0 {
        didSet {
            currentImageURL = images.isEmpty ? nil : images[currentIndex]
            preloadAdjacentImages()
        }
    }
    @Published var currentImageURL: URL? = nil
    
    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    private var imageCache = NSCache<NSURL, NSImage>()
    private let preloadQueue = DispatchQueue(label: "com.nectarview.imagepreload", qos: .utility)
    private var prefetchedImages: [URL: NSImage] = [:]
    private let prefetchRange = 5
    
    func loadImages(from url: URL) {
        if url.pathExtension.lowercased() == "zip" {
            loadImagesFromZip(url: url)
        } else {
            loadImagesFromFileOrFolder(url: url)
        }
    }
    
    private func loadImagesFromZip(url: URL) {
        do {
            guard let archive = Archive(url: url, accessMode: .read) else { 
                print("ZIPアーカイブを開けませんでした: \(url.path)")
                return 
            }
            
            var extractedImages: [URL] = []
            
            let tempDir = FileManager.default.temporaryDirectory
            let zipFileName = url.deletingPathExtension().lastPathComponent
            let extractionDir = tempDir.appendingPathComponent(zipFileName)
            
            try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true, attributes: nil)
            
            for entry in archive {
                let entryPath = entry.path
                
                if entryPath.hasPrefix("__MACOSX") || (entryPath as NSString).lastPathComponent.hasPrefix("._") {
                    continue
                }
                
                let entryPathExtension = (entryPath as NSString).pathExtension.lowercased()
                
                if !imageExtensions.contains(entryPathExtension) {
                    continue
                }
                
                let extractionPath = extractionDir.appendingPathComponent(entryPath)
                let extractionFolder = extractionPath.deletingLastPathComponent()
                
                try FileManager.default.createDirectory(at: extractionFolder, withIntermediateDirectories: true, attributes: nil)
                
                try archive.extract(entry, to: extractionPath)
                extractedImages.append(extractionPath)
            }
            
            DispatchQueue.main.async {
                self.images = extractedImages.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
                self.currentIndex = 0
            }
        } catch {
            print("ZIPアーカイブを開く際のエラー: \(error.localizedDescription)")
            showAlert(message: "ZIPファイルの展開中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    private func loadImagesFromFileOrFolder(url: URL) {
        let folderURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            
            let filteredImages = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.images = filteredImages
                if !self.images.isEmpty {
                    self.currentIndex = url.hasDirectoryPath ? 0 : (self.images.firstIndex(of: url) ?? 0)
                }
            }
        } catch {
            handleLoadError(url: url, error: error)
        }
    }
    
    private func handleLoadError(url: URL, error: Error) {
        print("エラーが発生しました: \(error.localizedDescription)")
        
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoPermissionError:
                showAlert(message: "ファイルへのアクセス権限がありません。アプリケーションの権限設定を確認してください。")
            case NSFileReadUnknownError:
                showAlert(message: "ファイルの読み込みに失敗しました。ファイルが存在するか確認してください。")
            default:
                showAlert(message: "予期せぬエラーが発生しました: \(nsError.localizedDescription)")
            }
        }
        
        if imageExtensions.contains(url.pathExtension.lowercased()) {
            DispatchQueue.main.async {
                self.images = [url]
                self.currentIndex = 0
            }
        } else {
            showAlert(message: "サポートされていないファイル形式です")
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "エラー"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    private func preloadAdjacentImages() {
        let adjacentIndices = [
            max(0, currentIndex - 1),
            min(images.count - 1, currentIndex + 1)
        ]
        
        for index in adjacentIndices {
            let url = images[index]
            preloadQueue.async { [weak self] in
                guard let self = self else { return }
                if self.imageCache.object(forKey: url as NSURL) == nil {
                    if let image = NSImage(contentsOf: url) {
                        self.imageCache.setObject(image, forKey: url as NSURL)
                    }
                }
            }
        }
    }
    
    func prefetchImages() {
        guard !images.isEmpty else { return }
        
        let start = max(0, currentIndex - prefetchRange)
        let end = min(images.count - 1, currentIndex + prefetchRange)
        
        for index in start...end {
            let url = images[index]
            if prefetchedImages[url] == nil {
                SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { [weak self] (image, _, _, _, _, _) in
                    if let image = image {
                        self?.prefetchedImages[url] = image
                    }
                }
            }
        }
    }
    
    func getImage(for url: URL) -> NSImage? {
        if let prefetchedImage = prefetchedImages[url] {
            return prefetchedImage
        }
        if let cachedImage = imageCache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        if let image = NSImage(contentsOf: url) {
            imageCache.setObject(image, forKey: url as NSURL)
            return image
        }
        
        return nil
    }
    
    func showNextImage() {
        if currentIndex < images.count - 1 {
            currentIndex += 1
        } else {
            playSound()
        }
    }
    
    func showPreviousImage() {
        if currentIndex > 0 {
            currentIndex -= 1
        } else {
            playSound()
        }
    }
    
    private func playSound() {
        NSSound(named: "Basso")?.play()
    }
}
