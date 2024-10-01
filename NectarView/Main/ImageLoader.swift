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
            updateCurrentImageInfo()
            preloadAdjacentImages()
        }
    }
    @Published var currentImageURL: URL? = nil
    @Published var currentSpreadIndices: (Int?, Int?) = (nil, nil)
    @Published var viewMode: ViewMode = .single {
        didSet {
            updateSpreadIndices(isSpreadViewEnabled: viewMode != .single, isRightToLeftReading: viewMode == .spreadRightToLeft)
        }
    }

    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    private var imageCache = NSCache<NSURL, NSImage>()
    private let preloadQueue = DispatchQueue(label: "com.nectarview.imagepreload", qos: .utility)
    private var prefetchedImages: [URL: NSImage] = [:]
    private let prefetchRange = 5
    
    private var currentZipArchive: Archive?
    private var zipImageEntries: [Entry] = []
    @Published var zipFileURL: URL?
    private var zipEntryPaths: [String] = []

    @Published var bookmarks: [Int] = []

    @Published var currentRotation: Angle = .degrees(0)

    enum ViewMode {
        case single
        case spreadLeftToRight
        case spreadRightToLeft
    }

    private var nestedArchives: [String: Archive] = [:]
    private var nestedImageEntries: [String: [Entry]] = [:]

    @Published private(set) var currentImageInfo: String = NSLocalizedString("NectarView", comment: "NectarView")
    private func updateCurrentImageInfo() {
        guard !images.isEmpty else {
            currentImageInfo = NSLocalizedString("NectarView", comment: "NectarView")
            return
        }

        let currentURL = images[currentIndex]
        let isZipFile = zipFileURL != nil

        if isZipFile {
            let zipFileName = zipFileURL?.lastPathComponent ?? ""
            let entryPath = zipEntryPaths[currentIndex]
            let entryComponents = entryPath.split(separator: "|")
            let entryFileName = entryComponents.count > 1 ? String(entryComponents[1]) : (entryPath as NSString).lastPathComponent

            currentImageInfo = "\(zipFileName) - \(entryFileName) (\(currentIndex + 1)/\(images.count))"
        } else {
            let folderPath = currentURL.deletingLastPathComponent().path
            let fileName = currentURL.lastPathComponent
            currentImageInfo = "\(folderPath)/\(fileName) (\(currentIndex + 1)/\(images.count))"
        }
    }

    func loadImages(from url: URL) {
        // 既存のデータをクリア
        clearExistingData()
        
        // ZIPファイルの状態をクリア
        clearZipData()
        
        // 画像のロード処理
        if url.pathExtension.lowercased() == "zip" {
            loadImagesFromZip(url: url)
        } else {
            loadImagesFromFileOrFolder(url: url)
        }
        
        // 画像のロード後にスプレッドインデックスを更新
        updateSpreadIndicesAfterLoading()
        
        // 画像のロード後にcurrentImageInfoを更新
        updateCurrentImageInfo()
    }
    
    // 既存のデータをクリアするヘルパー関数
    private func clearExistingData() {
        images = []
        currentIndex = 0
        currentImageURL = nil
    }
    
    // ZIPファイルの状態をクリアするヘルパー関数
    private func clearZipData() {
        currentZipArchive = nil
        zipImageEntries.removeAll()
        zipFileURL = nil
        zipEntryPaths.removeAll()
        imageCache.removeAllObjects()
        prefetchedImages.removeAll()
    }
    
    // 画像のロード後にスプレッドインデックスを更新するヘルパー関数
    private func updateSpreadIndicesAfterLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let isSpreadViewEnabled = UserDefaults.standard.bool(forKey: "isSpreadViewEnabled")
            let isRightToLeftReading = UserDefaults.standard.bool(forKey: "isRightToLeftReading")
            self.updateSpreadIndices(isSpreadViewEnabled: isSpreadViewEnabled, isRightToLeftReading: isRightToLeftReading)
            
            // 見開き表示の場合、2枚目の画像も読み込む
            if isSpreadViewEnabled {
                self.preloadNextImage()
            }
        }
    }
    
    private func loadImagesFromZip(url: URL) {
        do {
            currentZipArchive = nil
            imageCache.removeAllObjects()
            prefetchedImages.removeAll()

            let archive = try Archive(url: url, accessMode: .read)
            currentZipArchive = archive
            zipFileURL = url
            
            zipImageEntries = archive.filter { entry in
                let entryPath = entry.path
                let entryPathExtension = (entryPath as NSString).pathExtension.lowercased()
                return !entryPath.hasPrefix("__MACOSX") &&
                       !(entryPath as NSString).lastPathComponent.hasPrefix("._") &&
                       (imageExtensions.contains(entryPathExtension) || entryPathExtension == "zip")
            }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

            // 書庫内書庫の処理
            for entry in zipImageEntries where (entry.path as NSString).pathExtension.lowercased() == "zip" {
                if let nestedArchive = try? archive.extractArchive(from: entry) {
                    nestedArchives[entry.path] = nestedArchive
                    let nestedEntries = nestedArchive.filter { nestedEntry in
                        let nestedEntryPath = nestedEntry.path
                        let nestedEntryPathExtension = (nestedEntryPath as NSString).pathExtension.lowercased()
                        return imageExtensions.contains(nestedEntryPathExtension)
                    }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
                    nestedImageEntries[entry.path] = nestedEntries
                }
            }

            zipEntryPaths = zipImageEntries.flatMap { entry -> [String] in
                if (entry.path as NSString).pathExtension.lowercased() == "zip",
                   let nestedEntries = nestedImageEntries[entry.path] {
                    return nestedEntries.map { "\(entry.path)|\($0.path)" }
                } else {
                    return [entry.path]
                }
            }

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
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            
            let filteredImages = files.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.images = filteredImages
                if !self.images.isEmpty {
                    if url.hasDirectoryPath {
                        self.currentIndex = 0
                    } else {
                        // 単一ファイルが選択合、そのファイルのインデックスを見つける
                        if let selectedIndex = self.images.firstIndex(of: url) {
                            self.currentIndex = selectedIndex
                        } else {
                            // 選択されたファイルが見つからない合、最初の画像を表示
                            self.currentIndex = 0
                        }
                    }
                }
                self.currentImageURL = self.images.isEmpty ? nil : self.images[self.currentIndex]
            }
        } catch {
            if (error as NSError).code == NSFileReadNoPermissionError {
                // 権限がない場合、ユーザーに権限を要求
                FileUtil.requestAccessForURL(folderURL) { success in
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
    
    private func handleLoadError(url: URL, error: Error) {
        print("エラーが発生しました: \(error.localizedDescription)")
        print("問題のファイルパス: \(url.path)")
        
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoPermissionError:
                showAlert(message: "ファイルへのアクセス権限がありん。アプリケーションの権限設定を確認してください。\nファイルパス: \(url.path)")
            case NSFileReadUnknownError:
                showAlert(message: "ファイルの読み込に敗しました。ファイル存在するか確認してください。\nファイパス: \(url.path)")
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
            let index = images.firstIndex(of: url) ?? -1
            if index >= 0 && index < zipEntryPaths.count {
                let entryPath = zipEntryPaths[index]
                let pathComponents = entryPath.split(separator: "|")
                
                do {
                    if pathComponents.count == 2 {
                        // 書庫内書庫の画像
                        let outerZipPath = String(pathComponents[0])
                        let innerImagePath = String(pathComponents[1])
                        if let nestedArchive = nestedArchives[outerZipPath],
                           let nestedEntry = nestedArchive[innerImagePath] {
                            var imageData = Data()
                            _ = try nestedArchive.extract(nestedEntry) { data in
                                imageData.append(data)
                            }
                            
                            if let image = NSImage(data: imageData) {
                                imageCache.setObject(image, forKey: url as NSURL)
                                return image
                            }
                        }
                    } else {
                        // 通常の画像ファイル
                        guard let entry = zipImageEntries.first(where: { $0.path == entryPath }) else {
                            return nil
                        }
                        var imageData = Data()
                        _ = try zipArchive.extract(entry) { data in
                            imageData.append(data)
                        }
                        
                        if let image = NSImage(data: imageData) {
                            imageCache.setObject(image, forKey: url as NSURL)
                            return image
                        }
                    }
                } catch {
                    print("画像の展開中にエラーが発生しました: \(error.localizedDescription)")
                }
            }
        } else {
            // 通常のファイルシステム上の像の場合
            if let image = NSImage(contentsOf: url) {
                imageCache.setObject(image, forKey: url as NSURL)
                return image
            }
        }
        
        return nil
    }
    
    func updateSafeCurrentIndex(_ newIndex: Int) {
        currentIndex = max(0, min(newIndex, images.count - 1))
    }

    func showNextImage() {
        if currentIndex < images.count - 1 {
            updateSafeCurrentIndex(currentIndex + 1)
        } else {
            NSSound.beep()
        }
    }
    
    func showPreviousImage() {
        if currentIndex > 0 {
            updateSafeCurrentIndex(currentIndex - 1)
        } else {
            NSSound.beep()
        }
    }
    
    func updateSpreadIndices(isSpreadViewEnabled: Bool, isRightToLeftReading: Bool) {
        guard !images.isEmpty else {
            currentSpreadIndices = (nil, nil)
            return
        }

        if isSpreadViewEnabled {
            if isRightToLeftReading {
                if currentIndex == images.count - 1 {
                    currentSpreadIndices = (currentIndex, nil)
                } else {
                    currentSpreadIndices = (min(currentIndex + 1, images.count - 1), currentIndex)
                }
            } else {
                if currentIndex == images.count - 1 {
                    currentSpreadIndices = (currentIndex, nil)
                } else {
                    currentSpreadIndices = (currentIndex, min(currentIndex + 1, images.count - 1))
                }
            }
        } else {
            currentSpreadIndices = (currentIndex, nil)
        }
        
        updateCurrentImageInfo()
    }
    
    func showNextSpread(isRightToLeftReading: Bool) {
        currentIndex = min(images.count - 1, currentIndex + 2)
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: isRightToLeftReading)
    }

    func showPreviousSpread(isRightToLeftReading: Bool) {
        currentIndex = max(0, currentIndex - 2)
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: isRightToLeftReading)
    }
    
    private func preloadNextImage() {
        let nextIndex = currentIndex + 1
        if nextIndex < images.count {
            let url = images[nextIndex]
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

    func toggleViewMode(_ mode: ViewMode) {
        viewMode = mode
        updateCurrentImageInfo()
    }

    func toggleBookmark() {
        if bookmarks.contains(currentIndex) {
            bookmarks.removeAll { $0 == currentIndex }
        } else {
            bookmarks.append(currentIndex)
            bookmarks.sort()
        }
    }

    func isCurrentPageBookmarked() -> Bool {
        return bookmarks.contains(currentIndex)
    }

    func goToNextBookmark() {
        if let nextBookmark = bookmarks.first(where: { $0 > currentIndex }) {
            currentIndex = nextBookmark
        } else if let firstBookmark = bookmarks.first, firstBookmark < currentIndex {
            currentIndex = firstBookmark
        }
    }

    func goToPreviousBookmark() {
        if let previousBookmark = bookmarks.last(where: { $0 < currentIndex }) {
            currentIndex = previousBookmark
        } else if let lastBookmark = bookmarks.last, lastBookmark > currentIndex {
            currentIndex = lastBookmark
        }
    }

    public func openFile() {
        FileUtil.openFile { [weak self] url in
            guard let self = self, let url = url else { return }
            self.loadImages(from: url)
        }
    }

    func rotateImage(by degrees: Int) {
        currentRotation = currentRotation + .degrees(Double(degrees))
    }
}
