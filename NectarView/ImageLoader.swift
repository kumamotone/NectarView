import Foundation
import AppKit
import ZIPFoundation

class ImageLoader: ObservableObject {
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0 {
        didSet {
            currentImageURL = images.isEmpty ? nil : images[currentIndex]
        }
    }
    @Published var currentImageURL: URL? = nil
    
    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    
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
