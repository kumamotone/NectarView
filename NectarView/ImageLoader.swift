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
    @Published var currentSourcePath: String = ""

    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    private var imageCache = NSCache<NSURL, NSImage>()
    private let preloadQueue = DispatchQueue(label: "com.nectarview.imagepreload", qos: .utility)
    private var prefetchedImages: [URL: NSImage] = [:]
    private let prefetchRange = 5
    
    @AppStorage("lastOpenedURL") private var lastOpenedURL: String?
    @AppStorage("lastOpenedIndex") private var lastOpenedIndex: Int = 0
    
    private var currentZipArchive: Archive?
    private var zipImageEntries: [Entry] = []
    private var zipFileURL: URL?
    private var zipEntryPaths: [String] = []

    @AppStorage("folderBookmarks") private var folderBookmarks: Data = Data()
    
    func loadImages(from url: URL) {
        lastOpenedURL = url.absoluteString
        
        // ブックマークを作成または更新
        updateBookmark(for: url)
        
        // 既存のデータをクリア
        images = []
        currentIndex = 0
        currentImageURL = nil
        
        // ZIPファイルの状態をクリア
        currentZipArchive = nil
        zipImageEntries.removeAll()
        zipFileURL = nil
        zipEntryPaths.removeAll()
        
        // キャッシュをクリア
        imageCache.removeAllObjects()
        prefetchedImages.removeAll()

        if url.pathExtension.lowercased() == "zip" {
            loadImagesFromZip(url: url)
        } else {
            loadImagesFromFileOrFolder(url: url)
        }
        
        self.currentSourcePath = url.path
    }
    
    private func loadImagesFromZip(url: URL) {
        do {
            currentZipArchive = nil
            imageCache.removeAllObjects()
            prefetchedImages.removeAll()

            let archive = try Archive(url: url, accessMode: .read)
            currentZipArchive = archive
            zipFileURL = url
            
            // ZIPファイルの名前をタイトルとして設定
            currentTitle = url.lastPathComponent
            
            zipImageEntries = archive.filter { entry in
                let entryPath = entry.path
                let entryPathExtension = (entryPath as NSString).pathExtension.lowercased()
                return !entryPath.hasPrefix("__MACOSX") &&
                       !(entryPath as NSString).lastPathComponent.hasPrefix("._") &&
                       imageExtensions.contains(entryPathExtension)
            }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

            zipEntryPaths = zipImageEntries.map { $0.path }

            DispatchQueue.main.async {
                self.images = self.zipEntryPaths.indices.map { URL(fileURLWithPath: "zip://\($0)") }
                self.currentIndex = 0
                self.currentImageURL = self.images.first
            }
        } catch {
            print("ZIPアーカイブを開く際のエラー: \(error.localizedDescription)")
            showAlert(message: "ZIPファイルの読み込み中にエラーが発生しました: \(error.localizedDescription)")
            // エラーが発生した場合、画像リストをクリアし、インデックスをリセット
            DispatchQueue.main.async {
                self.images = []
                self.currentIndex = 0
                self.currentImageURL = nil
            }
        }
    }
    
    private func loadImagesFromFileOrFolder(url: URL) {
        // 既存のキャッシュをクリア
        imageCache.removeAllObjects()
        prefetchedImages.removeAll()

        let folderURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        
        // タイトルを設定
        currentTitle = url.hasDirectoryPath ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            
            let filteredImages = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            // フォルダ内の画像に対してブックマークを作成
            updateFolderBookmarks(for: filteredImages)
            
            DispatchQueue.main.async {
                self.images = filteredImages
                if !self.images.isEmpty {
                    if url.hasDirectoryPath {
                        self.currentIndex = 0
                    } else {
                        // 単一ファイルが選択された場合、そのファイルのインデックスを見つける
                        if let selectedIndex = self.images.firstIndex(of: url) {
                            self.currentIndex = selectedIndex
                        } else {
                            // 選択されたファイルが見つからない場合、最初の画像を表示
                            self.currentIndex = 0
                        }
                    }
                }
                self.currentImageURL = self.images.isEmpty ? nil : self.images[self.currentIndex]
            }
        } catch {
            if (error as NSError).code == NSFileReadNoPermissionError {
                // 権限がない場合、ユーザーに権限を要求
                requestAccessForURL(folderURL) { success in
                    if success {
                        // 権限が付与されたら、再度読み込みを試みる
                        self.loadImagesFromFileOrFolder(url: url)
                    } else {
                        self.handleLoadError(url: url, error: error)
                    }
                }
            } else {
                handleLoadError(url: url, error: error)
            }
        }
    }
    
    private func updateFolderBookmarks(for urls: [URL]) {
        var bookmarks: [Data] = []
        for url in urls {
            do {
                let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                bookmarks.append(bookmark)
            } catch {
                print("画像のブックマーク作成中にエラーが発生しました: \(error)")
            }
        }
        
        do {
            let encodedBookmarks = try JSONEncoder().encode(bookmarks)
            folderBookmarks = encodedBookmarks
        } catch {
            print("ブックマークのエンコード中にエラーが発生しました: \(error)")
        }
    }
    
    private func handleLoadError(url: URL, error: Error) {
        print("エラーが発生しました: \(error.localizedDescription)")
        print("問題のファイルパス: \(url.path)")
        
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoPermissionError:
                showAlert(message: "ファイルへのアクセス権限がありません。アプリケーションの権限設定を確認してください。\nファイルパス: \(url.path)")
            case NSFileReadUnknownError:
                showAlert(message: "ファイルの読み込みに失敗しました。ファイルが存在するか確認してください。\nファイルパス: \(url.path)")
            default:
                showAlert(message: "予期せぬエラーが発生しました: \(nsError.localizedDescription)\nファイルパス: \(url.path)")
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
        if let cachedImage = imageCache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        if let zipArchive = currentZipArchive, zipFileURL != nil {
            // ZIPファイル内の画像の場合
            let index = images.firstIndex(of: url) ?? -1
            if index >= 0 && index < zipEntryPaths.count {
                let entryPath = zipEntryPaths[index]
                guard let entry = zipImageEntries.first(where: { $0.path == entryPath }) else {
                    return nil
                }
                
                do {
                    var imageData = Data()
                    _ = try zipArchive.extract(entry) { data in
                        imageData.append(data)
                    }
                    
                    if let image = NSImage(data: imageData) {
                        imageCache.setObject(image, forKey: url as NSURL)
                        return image
                    }
                } catch {
                    print("画像の展開中にエラーが発生しました: \(error.localizedDescription)")
                }
            }
        } else {
            // 通常のファイルシステム上の画像の場合
            if let image = NSImage(contentsOf: url) {
                imageCache.setObject(image, forKey: url as NSURL)
                return image
            }
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
        guard let urlString = lastOpenedURL, let url = URL(string: urlString) else {
            print("前回のセッション情報が見つかりません")
            return
        }
        
        self.currentSourcePath = url.path
        
        if url.hasDirectoryPath {
            restoreFolderSession(url: url)
        } else {
            restoreFileSession(url: url)
        }
    }
    
    private func restoreFolderSession(url: URL) {
        do {
            let bookmarks = try JSONDecoder().decode([Data].self, from: folderBookmarks)
            var restoredURLs: [URL] = []
            
            for bookmarkData in bookmarks {
                var isStale = false
                do {
                    let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                    
                    if resolvedURL.startAccessingSecurityScopedResource() {
                        restoredURLs.append(resolvedURL)
                    } else {
                        print("画像へのアクセスが拒否されました: \(resolvedURL.path)")
                    }
                } catch {
                    print("画像のブックマーク解決中にエラーが発生しました: \(error)")
                }
            }
            
            if !restoredURLs.isEmpty {
                DispatchQueue.main.async {
                    self.images = restoredURLs
                    self.currentIndex = min(self.lastOpenedIndex, self.images.count - 1)
                    self.currentImageURL = self.images[self.currentIndex]
                }
            } else {
                showAlert(message: "フォルダ内の画像へのアクセスに失敗しました。フォルダを再度開いてください。")
            }
        } catch {
            print("フォルダブックマークのデコード中にエラーが発生しました: \(error)")
            showAlert(message: "前回開いたフォルダの情報を復元できませんでした。フォルダを再度開いてください。")
        }
    }
    
    private func restoreFileSession(url: URL) {
        // セキュリティスコープドブックマークを使用してアクセス権限を取得
        if let bookmarkData = UserDefaults.standard.data(forKey: "lastOpenedURLBookmark") {
            var isStale = false
            do {
                let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    // ブックマークが古くなっている場合は更新
                    updateBookmark(for: url)
                }
                
                // セキュリティスコープドリソースへのアクセスを開始
                if resolvedURL.startAccessingSecurityScopedResource() {
                    defer {
                        resolvedURL.stopAccessingSecurityScopedResource()
                    }
                    
                    loadImages(from: resolvedURL)
                    DispatchQueue.main.async {
                        self.currentIndex = min(self.lastOpenedIndex, self.images.count - 1)
                    }
                } else {
                    print("セキュリティスコープドリソースへのアクセスが拒否されました")
                    showAlert(message: "ファイルへのアクセスが拒否されました。アプリケーションの権限設定を確認してください。")
                }
            } catch {
                print("ブックマークの解決中にエラーが発生しました: \(error)")
                showAlert(message: "前回開いたファイルへのアクセスに失敗しました。ファイルを再度開いてください。")
            }
        } else {
            print("ブックマークデータが見つかりません")
            showAlert(message: "前回開いたファイルの情報が見つかりません。ファイルを再度開いてください。")
        }
    }
    
    private func updateBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: "lastOpenedURLBookmark")
        } catch {
            print("ブックマークの更新中にエラーが発生しました: \(error)")
        }
    }
    
    func updateLastOpenedIndex() {
        lastOpenedIndex = currentIndex
    }

    func requestAccessForURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = url
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.prompt = "フォルダへのアクセスを許可"
        openPanel.message = "このフォルダ内の画像を表示するには、アクセス権限が必要です。"

        openPanel.begin { result in
            if result == .OK {
                if let selectedURL = openPanel.url {
                    // 選択されたURLに対する権限を取得
                    self.updateBookmark(for: selectedURL)
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}
