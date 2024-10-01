import Foundation
import AppKit
import ZIPFoundation
import SDWebImage
import SwiftUI

class ImageLoader: ObservableObject {
    // MARK: - Published properties
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0 {
        didSet {
            updateCurrentImage()
        }
    }
    @Published var currentImages: (Int?, Int?) = (nil, nil)
    @Published private(set) var viewMode: ViewMode = .single
    @Published var zipFileURL: URL?
    @Published var bookmarks: [Int] = []
    @Published var currentRotation: Angle = .degrees(0)
    @Published private(set) var currentImageInfo: String = NSLocalizedString("NectarView", comment: "NectarView")

    var zipEntryPaths: [String] = [] // for testing

    // MARK: - Private properties
    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    private var imageCache = NSCache<NSURL, NSImage>()
    private lazy var preloadQueue: DispatchQueue = {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.unknown"
        return DispatchQueue(label: "\(bundleIdentifier).imagepreload", qos: .utility)
    }()
    private var prefetchedImages: [URL: NSImage] = [:]
    private let prefetchRange = 5

    private var currentZipArchive: Archive?
    private var zipImageEntries: [Entry] = []
    private var nestedArchives: [String: Archive] = [:]
    private var nestedImageEntries: [String: [Entry]] = [:]

    // MARK: - Public methods
    func loadImages(from url: URL) {
        clearExistingData()
        clearZipData()

        if url.pathExtension.lowercased() == "zip" {
            loadImagesFromZip(url: url)
        } else {
            loadImagesFromFileOrFolder(url: url)
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
                    print("Error extracting image: \(error.localizedDescription)")
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

    func showPreviousImage() {
        switch viewMode {
        case .single:
            if currentIndex > 0 {
                currentIndex -= 1
            }
        case .spreadLeftToRight, .spreadRightToLeft:
            if currentIndex > 1 {
                currentIndex -= 2
            } else if currentIndex == 1 {
                currentIndex = 0
            }
        }
        updateCurrentImage()
    }

    func showNextImage() {
        switch viewMode {
        case .single:
            if currentIndex < images.count - 1 {
                currentIndex += 1
            }
        case .spreadLeftToRight, .spreadRightToLeft:
            if currentIndex < images.count - 2 {
                currentIndex += 2
            } else if currentIndex == images.count - 2 {
                currentIndex = images.count - 1
            }
        }
        updateCurrentImage()
    }

    func updateCurrentImage() {
        guard !images.isEmpty else {
            currentImages = (nil, nil)
            return
        }

        switch viewMode {
        case .single:
            currentImages = (currentIndex, nil)
        case .spreadLeftToRight:
            let leftIndex = currentIndex
            let rightIndex = min(currentIndex + 1, images.count - 1)
            currentImages = (leftIndex, rightIndex == leftIndex ? nil : rightIndex)
        case .spreadRightToLeft:
            let rightIndex = currentIndex
            let leftIndex = min(currentIndex + 1, images.count - 1)
            currentImages = (leftIndex == rightIndex ? nil : leftIndex, rightIndex)
        }

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

    func openFile() {
        FileUtil.openFile { [weak self] url in
            guard let self = self, let url = url else { return }
            self.loadImages(from: url)
        }
    }

    func rotateImage(by degrees: Int) {
        currentRotation = currentRotation + .degrees(Double(degrees))
    }

    func updateViewMode(appSettings: AppSettings) {
        if appSettings.isSpreadViewEnabled {
            viewMode = appSettings.isRightToLeftReading ? .spreadRightToLeft : .spreadLeftToRight
        } else {
            viewMode = .single
        }
        updateCurrentImage()
    }

    // MARK: - Private methods
    private func clearExistingData() {
        images = []
        currentIndex = 0
    }

    private func clearZipData() {
        currentZipArchive = nil
        zipImageEntries.removeAll()
        zipFileURL = nil
        zipEntryPaths.removeAll()
        imageCache.removeAllObjects()
        prefetchedImages.removeAll()
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
            }
        } catch {
            print("Error loading ZIP file: \(error.localizedDescription)")
            ErrorUtil.showAlert(message: NSLocalizedString("Error loading ZIP file: \(error.localizedDescription)", comment: ""))
            // エラーが発生した場合、画像リストをクリアし、インデックスをリセット
            DispatchQueue.main.async {
                self.images = []
                self.currentIndex = 0
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
                        // 単一ファイルが選択された場合、そのファイルのインデックスを見つける
                        if let selectedIndex = self.images.firstIndex(of: url) {
                            self.currentIndex = selectedIndex
                        } else {
                            // 選択されたファイルが見つからない場合、最初の画像を表示
                            self.currentIndex = 0
                        }
                    }
                }
                self.updateCurrentImage()
            }
        } catch {
            if (error as NSError).code == NSFileReadNoPermissionError {
                // 権限がない場合、ユーザーに権限を要求
                FileUtil.requestAccessForURL(folderURL) { success in
                    if success {
                        // 権限が付与されたら、再度読み込みを試みる
                        self.loadImagesFromFileOrFolder(url: url)
                    }
                }
            } else {
                ErrorUtil.handleLoadError(url: url, error: error) {
                    if self.imageExtensions.contains(url.pathExtension.lowercased()) {
                        DispatchQueue.main.async {
                            self.images = [url]
                            self.currentIndex = 0
                        }
                    } else {
                        ErrorUtil.showAlert(message: "サポートされていないファイル形式です")
                    }
                }
            }
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

    private func prefetchImages() {
        guard !images.isEmpty else { return }

        let start = max(0, currentIndex - prefetchRange)
        let end = min(images.count - 1, currentIndex + prefetchRange)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            for index in start...end {
                let url = self.images[index]
                if self.prefetchedImages[url] == nil {
                    if let image = self.loadImageFromSource(url: url) {
                        DispatchQueue.main.async {
                            self.prefetchedImages[url] = image
                        }
                    }
                }
            }
        }
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

    private func updateCurrentImageInfo() {
        guard !images.isEmpty else {
            currentImageInfo = NSLocalizedString("NectarView", comment: "NectarView")
            return
        }

        let currentImageIndex: Int
        switch viewMode {
        case .single:
            guard let index = currentImages.0 else { return }
            currentImageIndex = index
        case .spreadLeftToRight:
            guard let index = currentImages.0 else { return }
            currentImageIndex = index
        case .spreadRightToLeft:
            guard let index = currentImages.1 ?? currentImages.0 else { return }
            currentImageIndex = index
        }

        let currentURL = images[currentImageIndex]
        let isZipFile = zipFileURL != nil

        if isZipFile {
            let zipFileName = zipFileURL?.lastPathComponent ?? ""
            let entryPath = zipEntryPaths[currentImageIndex]
            let entryComponents = entryPath.split(separator: "|")
            let entryFileName = entryComponents.count > 1 ? String(entryComponents[1]) : (entryPath as NSString).lastPathComponent

            currentImageInfo = "\(zipFileName) - \(entryFileName) (\(currentImageIndex + 1)/\(images.count))"
        } else {
            let folderPath = currentURL.deletingLastPathComponent().path
            let fileName = currentURL.lastPathComponent
            currentImageInfo = "\(folderPath)/\(fileName) (\(currentImageIndex + 1)/\(images.count))"
        }
    }

    private func loadImageFromSource(url: URL) -> NSImage? {
        if let _ = currentZipArchive, zipFileURL != nil {
            return loadImageFromZip(url: url)
        } else {
            return NSImage(contentsOf: url)
        }
    }

    private func loadImageFromZip(url: URL) -> NSImage? {
        let index = images.firstIndex(of: url) ?? -1
        guard index >= 0 && index < zipEntryPaths.count else { return nil }

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
                    return NSImage(data: imageData)
                }
            } else {
                // 通常の画像ファイル
                guard let entry = zipImageEntries.first(where: { $0.path == entryPath }) else {
                    return nil
                }
                var imageData = Data()
                _ = try currentZipArchive?.extract(entry) { data in
                    imageData.append(data)
                }
                return NSImage(data: imageData)
            }
        } catch {
            print("Error extracting image: \(error.localizedDescription)")
        }
        return nil
    }
}
