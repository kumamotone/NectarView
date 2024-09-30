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
    @Published var currentTitle: String = "NectarView"
    @Published var currentSourcePath: String = ""
    @Published var currentFolderPath: String = ""
    @Published var currentFileName: String = ""
    @Published var currentSpreadIndices: (Int?, Int?) = (nil, nil)
    @Published var currentZipFileName: String?
    @Published var currentZipEntryFileName: String?
    @Published var currentImageInfo: String = NSLocalizedString("NoImagesLoaded", comment: "画像がロードされていません")
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

    enum ViewMode {
        case single
        case spreadLeftToRight
        case spreadRightToLeft
    }

    func loadImages(from url: URL) {
        // 既存のデータをクリア
        images = []
        currentIndex = 0
        currentImageURL = nil
        
        // ZIPファイルの状態をクリア
        currentZipArchive = nil
        zipImageEntries.removeAll()
        zipFileURL = nil
        zipEntryPaths.removeAll()
        
        // ZIPファイル関連の情報をクリア
        currentZipFileName = nil
        currentZipEntryFileName = nil
        
        // キャッシュをクリア
        imageCache.removeAllObjects()
        prefetchedImages.removeAll()

        if url.pathExtension.lowercased() == "zip" {
            loadImagesFromZip(url: url)
        } else {
            loadImagesFromFileOrFolder(url: url)
        }
        
        self.currentSourcePath = url.path
        updateCurrentFolderAndFileName(url: url)
        
        // 画像のロード後に必ずupdateSpreadIndicesを呼び出す
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
        updateCurrentImageInfo()
    }
    
    private func updateCurrentFolderAndFileName(url: URL) {
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
        if let currentZipArchive = currentZipArchive,
           currentIndex < zipEntryPaths.count {
            currentZipEntryFileName = (zipEntryPaths[currentIndex] as NSString).lastPathComponent
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
            
            // ZIPファイルの名を設定
            currentZipFileName = url.lastPathComponent
            currentTitle = url.lastPathComponent
            currentFolderPath = url.deletingLastPathComponent().path
            currentFileName = url.lastPathComponent
            
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
        currentTitle = url.hasDirectoryPath ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
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
                        // 単一ファイルが選択された場合、そのファイルのインデックスを見つける
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
                showAlert(message: "ファイルの読み込に敗しました。ファイルが存在するか確認してください。\nファイルパス: \(url.path)")
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
        updateCurrentImageInfo()
    }
    
    func showPreviousImage() {
        if currentIndex > 0 {
            currentIndex -= 1
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

        let safeCurrentIndex = min(max(currentIndex, 0), images.count - 1)

        if isSpreadViewEnabled {
            if isRightToLeftReading {
                if safeCurrentIndex == images.count - 1 {
                    // 最後のページの場合、1ページだけ表示
                    currentSpreadIndices = (nil, safeCurrentIndex)
                } else {
                    let rightIndex = safeCurrentIndex
                    let leftIndex = rightIndex + 1 < images.count ? rightIndex + 1 : nil
                    currentSpreadIndices = (leftIndex, rightIndex)
                }
                currentIndex = safeCurrentIndex
            } else {
                if safeCurrentIndex == 0 {
                    // 最初のページの場合、1ページだけ表示
                    currentSpreadIndices = (safeCurrentIndex, nil)
                } else {
                    let leftIndex = safeCurrentIndex % 2 == 0 ? safeCurrentIndex - 1 : safeCurrentIndex
                    let rightIndex = leftIndex + 1 < images.count ? leftIndex + 1 : nil
                    currentSpreadIndices = (leftIndex, rightIndex)
                }
                currentIndex = currentSpreadIndices.0 ?? safeCurrentIndex
            }
        } else {
            currentSpreadIndices = (nil, safeCurrentIndex)
            currentIndex = safeCurrentIndex
        }
        
        // 現在のインデックスが変更されたことを通知
        objectWillChange.send()
        updateCurrentImageInfo()
    }
    
    func showNextSpread(isRightToLeftReading: Bool) {
        if isRightToLeftReading {
            if currentIndex > 1 {
                currentIndex -= 2
            } else if currentIndex == 1 {
                currentIndex = 0
            } else {
                playSound()
            }
        } else {
            if currentIndex < images.count - 2 {
                currentIndex += 2
            } else if currentIndex == images.count - 2 {
                currentIndex = images.count - 1
            } else {
                playSound()
            }
        }
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: isRightToLeftReading)
        updateCurrentImageInfo()
    }
    
    func showPreviousSpread(isRightToLeftReading: Bool) {
        if isRightToLeftReading {
            if currentIndex < images.count - 2 {
                currentIndex += 2
            } else if currentIndex == images.count - 2 {
                currentIndex = images.count - 1
            } else {
                playSound()
            }
        } else {
            if currentIndex > 1 {
                currentIndex -= 2
            } else if currentIndex == 1 {
                currentIndex = 0
            } else {
                playSound()
            }
        }
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: isRightToLeftReading)
        updateCurrentImageInfo()
    }
    
    func showNextSpreadSimple() {
        if currentIndex < images.count - 2 {
            currentIndex += 2
        } else if currentIndex == images.count - 2 {
            currentIndex = images.count - 1
        } else {
            playSound()
        }
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
        updateCurrentImageInfo()
    }
    
    func showPreviousSpreadSimple() {
        if currentIndex > 1 {
            currentIndex -= 2
        } else if currentIndex == 1 {
            currentIndex = 0
        } else {
            playSound()
        }
        updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
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
        openPanel.message = "このフォルダ内の画像を表示するには、アクセス権限が必要です。"

        openPanel.begin { result in
            if result == .OK {
                if let selectedURL = openPanel.url {
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
        if images.isEmpty {
            currentImageInfo = NSLocalizedString("NoImagesLoaded", comment: "画像がロードされていません")
        } else {
            let currentFileInfo: String
            if let zipFileName = currentZipFileName {
                if let entryFileName = currentZipEntryFileName {
                    currentFileInfo = "ZIP: \(zipFileName) - \(entryFileName)"
                } else {
                    currentFileInfo = "ZIP: \(zipFileName)"
                }
            } else {
                currentFileInfo = "File: \(currentFolderPath)/\(currentFileName)"
            }
            currentImageInfo = "\(currentFileInfo) (\(currentIndex + 1)/\(images.count))"
        }
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

    func rotateImage(by degrees: Double) {
        // 回転処理を実装
        // 注意: この実装は単純な例です。実際には回転状態を保存し、
        // 画像の表示時に適用する必要があるかもしれません。
        print("画像を\(degrees)度回転")
    }
}