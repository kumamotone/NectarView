import Foundation
import AppKit
import ZIPFoundation
import SDWebImage
import SwiftUI

class ImageLoader: ObservableObject {
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0 {
        didSet {
            currentImageURL = images.isEmpty ? nil : images[currentIndex]
            preloadAdjacentImages()
            updateLastOpenedIndex()
        }
    }
    @Published var currentImageURL: URL? = nil
    @Published var currentTitle: String = "NectarView"
    
    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    private var imageCache = NSCache<NSURL, NSImage>()
    private let preloadQueue = DispatchQueue(label: "com.nectarview.imagepreload", qos: .utility)
    private var prefetchedImages: [URL: NSImage] = [:]
    private let prefetchRange = 5
    
    @AppStorage("lastOpenedURL") private var lastOpenedURL: String?
    @AppStorage("lastOpenedIndex") private var lastOpenedIndex: Int = 0
    
    private var currentZipExtractionDir: URL?
    private var previousZipExtractionDir: URL?

    func loadImages(from url: URL) {
        lastOpenedURL = url.absoluteString
        
        if url.pathExtension.lowercased() == "zip" {
            currentTitle = url.lastPathComponent
            cleanupTemporaryDirectory()
            loadImagesFromZip(url: url)
        } else {
            currentTitle = url.deletingLastPathComponent().lastPathComponent
            loadImagesFromFileOrFolder(url: url)
        }
    }
    
    private func loadImagesFromZip(url: URL) {
        do {
            let archive = try Archive(url: url, accessMode: .read)

            let tempDir = FileManager.default.temporaryDirectory
            let zipFileName = url.deletingPathExtension().lastPathComponent
            let extractionDir = tempDir.appendingPathComponent(zipFileName)

            if !FileManager.default.fileExists(atPath: extractionDir.path) {
                try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true, attributes: nil)
            }

            previousZipExtractionDir = currentZipExtractionDir
            currentZipExtractionDir = extractionDir

            var extractedImages: [URL] = []

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

                if !FileManager.default.fileExists(atPath: extractionPath.path) {
                    try FileManager.default.createDirectory(at: extractionFolder, withIntermediateDirectories: true, attributes: nil)
                    _ = try archive.extract(entry, to: extractionPath)
                }
                extractedImages.append(extractionPath)
            }

            DispatchQueue.main.async {
                self.images = extractedImages.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
                self.currentIndex = 0
            }
        } catch {
            print("ZIPアーカイブを開く際のエラー: \(error.localizedDescription)")
            showAlert(message: "ZIPファイルの展開中にエラーが発生しました: \(error.localizedDescription)")
            // エラーが発生した場合、画像リストをクリアし、インデックスをリセット
            DispatchQueue.main.async {
                self.images = []
                self.currentIndex = 0
                self.currentImageURL = nil
            }
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
        guard !images.isEmpty else { return }
        
        let adjacentIndices = [
            max(0, currentIndex - 1),
            min(images.count - 1, currentIndex + 1)
        ]
        
        for index in adjacentIndices {
            guard index >= 0 && index < images.count else { continue }
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
        NSSound.beep()
    }
    
    func restoreLastSession() {
        if let urlString = lastOpenedURL, let url = URL(string: urlString) {
            if url.pathExtension.lowercased() == "zip" {
                currentTitle = url.lastPathComponent
                restoreZipSession(originalURL: url)
            } else {
                currentTitle = url.deletingLastPathComponent().lastPathComponent
                loadImages(from: url)
            }
            DispatchQueue.main.async {
                self.currentIndex = min(self.lastOpenedIndex, self.images.count - 1)
            }
        }
    }
    
    private func restoreZipSession(originalURL: URL) {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let zipFileName = originalURL.deletingPathExtension().lastPathComponent
            let extractionDir = tempDir.appendingPathComponent(zipFileName)

            if !FileManager.default.fileExists(atPath: extractionDir.path) {
                try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true, attributes: nil)
            }

            currentZipExtractionDir = extractionDir

            let archive = try Archive(url: originalURL, accessMode: .read)

            var extractedImages: [URL] = []

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

                if !FileManager.default.fileExists(atPath: extractionPath.path) {
                    try FileManager.default.createDirectory(at: extractionFolder, withIntermediateDirectories: true, attributes: nil)
                    _ = try archive.extract(entry, to: extractionPath)
                }
                extractedImages.append(extractionPath)
            }

            DispatchQueue.main.async {
                self.images = extractedImages.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            }

        } catch {
            print("ZIPセッションの復元中にエラーが発生しました: \(error.localizedDescription)")
            showAlert(message: "前回のZIPセッションの復元中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    // currentIndexが変更されたときに呼ばれるメソッド
    func updateLastOpenedIndex() {
        lastOpenedIndex = currentIndex
    }
    
    private func cleanupTemporaryDirectory() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory

        do {
            let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: [])
            for url in contents {
                if url != previousZipExtractionDir && url != currentZipExtractionDir {
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            print("一時ディレクトリのクリーンアップ中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
}
