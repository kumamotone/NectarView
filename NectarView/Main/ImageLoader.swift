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
            updateCurrentFileName()
            preloadAdjacentImages()
            updateCurrentImageInfo()
        }
    }
    @Published var currentImageURL: URL? = nil
    @Published var currentSourcePath: String = ""
    @Published var currentFolderPath: String = ""
    @Published var currentFileName: String = ""
    @Published var currentSpreadIndices: (Int?, Int?) = (nil, nil)
    @Published var currentZipFileName: String?
    @Published var currentZipEntryFileName: String?
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

    private var imageInfo: ImageInfo {
        return ImageInfo(imageLoader: self)
    }

    var currentImageInfo: String {
        return imageInfo.current
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
        
        // 現在のフォルダとファイル名を更新
        updateCurrentFolderAndFileName(url: url)
        
        // 画像のロード後にスプレッドインデックスを更新
        updateSpreadIndicesAfterLoading()
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
        currentZipFileName = nil
        currentZipEntryFileName = nil
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
    
    func updateCurrentFolderAndFileName(url: URL) {
        if url.hasDirectoryPath {
            currentFolderPath = url.path
            currentFileName = ""
        } else {
            currentFolderPath = url.deletingLastPathComponent().path
            currentFileName = url.lastPathComponent
        }
    }
    
    private func updateCurrentFileName() {
        if !images.isEmpty && currentIndex < images.count {
            if currentZipArchive != nil {
                updateCurrentZipEntryFileName()
            } else {
                currentFileName = images[currentIndex].lastPathComponent
            }
        } else {
            currentFileName = ""
            currentZipEntryFileName = nil
        }
    }
    
    private func updateCurrentZipEntryFileName() {
        if let _ = currentZipArchive,
           currentIndex < zipEntryPaths.count {
            let entryPath = zipEntryPaths[currentIndex]
            let pathComponents = entryPath.split(separator: "|")
            if pathComponents.count == 2 {
                currentZipEntryFileName = String(pathComponents[1])
            } else {
                currentZipEntryFileName = (entryPath as NSString).lastPathComponent
            }
        } else {
            currentZipEntryFileName = nil
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
            
            currentZipFileName = url.lastPathComponent
            currentFolderPath = url.deletingLastPathComponent().path
            currentFileName = url.lastPathComponent
            
            zipImageEntries = archive.filter { entry in
                let entryPath = entry.path
                let entryPathExtension = (entryPath as NSString).pathExtension.lowercased()
                return !entryPath.hasPrefix("__MACOSX") &&
                       !(entryPath as NSString).lastPathComponent.hasPrefix("._") &&
                       (imageExtensions.contains(entryPathExtension) || entryPathExtension == "zip")
            }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

            // 書庫内書庫の処理
            for entry in zipImageEntries where (entry.path as NSString).pathExtension.lowercased() == "zip" {
                if let nestedArchive = try? archive.extractArchive(entry) {
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
                self.updateCurrentZipEntryFileName()
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
        
        // タイトルとパス情報を設定
        updateCurrentFolderAndFileName(url: url)
        
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
                self.updateCurrentFileName()
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
            playSound()
        }
        updateCurrentImageInfo()
    }
    
    func showPreviousImage() {
        if currentIndex > 0 {
            updateSafeCurrentIndex(currentIndex - 1)
        } else {
            playSound()
        }
        updateCurrentImageInfo()
    }
    
    private func playSound() {
        NSSound.beep()
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
        
        objectWillChange.send()
        updateCurrentImageInfo()
    }
    
    func showNextSpread(isRightToLeftReading: Bool) {
        currentIndex = min(images.count - 1, currentIndex + 2)
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: isRightToLeftReading)
        updateCurrentImageInfo()
    }

    func showPreviousSpread(isRightToLeftReading: Bool) {
        currentIndex = max(0, currentIndex - 2)
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: isRightToLeftReading)
        updateCurrentImageInfo()
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
    
    func requestAccessForURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = url
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.prompt = "フォルダへのアクセスを許可"
        openPanel.message = "このフォルダ内の画像を表示するには、アクセス権が必要です。"

        openPanel.begin { result in
            if result == .OK {
                if openPanel.url != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }

    func updateCurrentImageInfo() {
        objectWillChange.send()
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
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.folder, .image, .archive]

        if panel.runModal() == .OK {
            if let url = panel.url {
                self.loadImages(from: url)
            }
        }
    }

    func rotateImage(by degrees: Int) {
        currentRotation = currentRotation + .degrees(Double(degrees))
        objectWillChange.send()
    }
}

extension Archive {
    func extractArchive(_ entry: Entry) throws -> Archive? {
        var archiveData = Data()
        _ = try self.extract(entry) { data in
            archiveData.append(data)
        }
        let archive = try Archive(data: archiveData, accessMode: .read)
        return archive
    }
}