import Foundation
import AppKit
import ZIPFoundation
import SwiftUI
import PDFKit
import CoreImage
import XADMasterSwift

enum ImageFilter: String, CaseIterable {
    case none = "None"
    case sepia = "Sepia"
    case mono = "Mono"
    case noir = "Noir"
    case invert = "Invert"
    case vibrant = "Vibrant"
    case fade = "Fade"
    case chrome = "Chrome"
    case instant = "Instant"
    case process = "Process"
    case tonal = "Tonal"
    case transfer = "Transfer"

    var filterName: String? {
        switch self {
        case .none: return nil
        case .sepia: return "CISepiaTone"
        case .mono: return "CIPhotoEffectMono"
        case .noir: return "CIPhotoEffectNoir"
        case .invert: return "CIColorInvert"
        case .vibrant: return "CIVibrance"
        case .fade: return "CIPhotoEffectFade"
        case .chrome: return "CIPhotoEffectChrome"
        case .instant: return "CIPhotoEffectInstant"
        case .process: return "CIPhotoEffectProcess"
        case .tonal: return "CIPhotoEffectTonal"
        case .transfer: return "CIPhotoEffectTransfer"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .sepia:
            return [kCIInputIntensityKey: 1.0]
        case .vibrant:
            return [kCIInputAmountKey: 1.0]
        default:
            return [:]
        }
    }
}

class ImageLoader: ObservableObject {
    // MARK: - Published properties
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0 {
        didSet {
            updateCurrentImage()
            preloadAdjacentImages()
        }
    }
    @Published var currentImages: (Int?, Int?) = (nil, nil)
    @Published private(set) var viewMode: ViewMode = .single
    @Published var archiveFileURL: URL?
    @Published var bookmarks: [Int] = []
    @Published var currentRotation: Angle = .degrees(0)
    @Published private(set) var currentImageInfo: String = NSLocalizedString("NectarView", comment: "NectarView")

    @Published var currentPDFDocument: PDFDocument?

    var archiveEntryPaths: [String] = [] // for testing

    // zipFileURL / zipEntryPaths の後方互換性
    var zipFileURL: URL? {
        get { archiveFileURL }
        set { archiveFileURL = newValue }
    }
    var zipEntryPaths: [String] {
        get { archiveEntryPaths }
        set { archiveEntryPaths = newValue }
    }

    @Published var isInitialLoad = true

    @Published var currentFilter: ImageFilter = .none
    private let context = CIContext()

    // パスワード入力が必要な場合のコールバック
    @Published var needsPassword: Bool = false
    private var pendingPasswordURL: URL?

    // MARK: - Private properties
    private let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]
    private var imageCache = NSCache<NSURL, NSImage>()
    private lazy var preloadQueue: DispatchQueue = {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.unknown"
        return DispatchQueue(label: "\(bundleIdentifier).imagepreload", qos: .utility)
    }()

    // ZIP (ZIPFoundation)
    private var currentZipArchive: Archive?
    private var zipImageEntries: [Entry] = []
    private var nestedArchives: [String: Archive] = [:]
    private var nestedImageEntries: [String: [Entry]] = [:]

    // XAD (RAR, 7z, etc.)
    private var currentXADArchive: XADArchiveReader?
    private var xadEntryIndices: [Int] = [] // XADArchiveのエントリインデックス（画像のみ）

    private var bookmarkManager = BookmarkManager()

    private let supportedExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp", "pdf"]

    static let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "lha", "lzh", "cab", "sit", "sitx"]

    // MARK: - Public methods
    func loadImages(from url: URL) {
        isInitialLoad = false
        clearExistingData()
        clearArchiveData()

        let ext = url.pathExtension.lowercased()
        if ext == "zip" {
            loadImagesFromZip(url: url)
        } else if ext == "pdf" {
            loadPDF(url: url)
        } else if Self.archiveExtensions.contains(ext) {
            loadImagesFromXADArchive(url: url)
        } else {
            loadImagesFromFileOrFolder(url: url)
        }

        // ブックマークを読み込む
        bookmarks = bookmarkManager.loadBookmarks(for: url)
    }

    func retryWithPassword(_ password: String) {
        guard let url = pendingPasswordURL else { return }
        needsPassword = false
        pendingPasswordURL = nil
        loadImagesFromXADArchive(url: url, password: password)
        bookmarks = bookmarkManager.loadBookmarks(for: url)
    }

    func cancelPasswordEntry() {
        needsPassword = false
        pendingPasswordURL = nil
    }

    @MainActor func getImage(for url: URL) -> NSImage? {
        let cacheKey = URL(string: "\(url.absoluteString)_\(currentFilter.rawValue)")!

        if let cachedImage = imageCache.object(forKey: cacheKey as NSURL) {
            return cachedImage
        }

        if url.scheme == "pdf" {
            return getImageFromPDF(url: url, cacheKey: cacheKey)
        } else if url.scheme == "xad" {
            return getImageFromXAD(url: url, cacheKey: cacheKey)
        } else if currentZipArchive != nil, archiveFileURL != nil {
            return getImageFromZip(url: url, cacheKey: cacheKey)
        } else {
            return getImageFromFilesystem(url: url, cacheKey: cacheKey)
        }
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

        if let url = archiveFileURL ?? images.first?.deletingLastPathComponent() {
            bookmarkManager.saveBookmarks(bookmarks, for: url)
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
        currentRotation += .degrees(Double(degrees))
    }

    func updateViewMode(appSettings: AppSettings) {
        if appSettings.isSpreadViewEnabled {
            viewMode = appSettings.isRightToLeftReading ? .spreadRightToLeft : .spreadLeftToRight
        } else {
            viewMode = .single
        }
        updateCurrentImage()
    }

    func getDisplayName(for url: URL, at index: Int) -> String {
        if archiveFileURL != nil {
            if index < archiveEntryPaths.count {
                let entryPath = archiveEntryPaths[index]
                let entryComponents = entryPath.split(separator: "|")
                if entryComponents.count > 1 {
                    return String(entryComponents[1])
                } else {
                    return (entryPath as NSString).lastPathComponent
                }
            }
            return url.lastPathComponent
        } else {
            return url.lastPathComponent
        }
    }

    // MARK: - Private: getImage helpers

    private func getImageFromPDF(url: URL, cacheKey: URL) -> NSImage? {
        guard let pdfDocument = currentPDFDocument,
              let pageNumber = Int(url.host ?? ""),
              let pdfPage = pdfDocument.page(at: pageNumber) else {
            return nil
        }

        let pageRect = pdfPage.bounds(for: .mediaBox)
        let scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
        let scaledSize = NSSize(width: pageRect.width * scale, height: pageRect.height * scale)
        let image = NSImage(size: pageRect.size)

        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(scaledSize.width),
            pixelsHigh: Int(scaledSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        bitmapRep.size = pageRect.size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        if let cgContext = NSGraphicsContext.current?.cgContext {
            cgContext.scaleBy(x: scale, y: scale)
            pdfPage.draw(with: .mediaBox, to: cgContext)
        }
        NSGraphicsContext.restoreGraphicsState()

        image.addRepresentation(bitmapRep)
        imageCache.setObject(image, forKey: url as NSURL)
        return image
    }

    private func getImageFromXAD(url: URL, cacheKey: URL) -> NSImage? {
        guard let xadArchive = currentXADArchive else { return nil }
        let index = images.firstIndex(of: url) ?? -1
        guard index >= 0 && index < xadEntryIndices.count else { return nil }

        let entryIndex = xadEntryIndices[index]
        guard let data = xadArchive.contentsOfEntry(at: entryIndex) else { return nil }
        guard let image = NSImage(data: data) else { return nil }

        if let filteredImage = applyFilter(to: image) {
            imageCache.setObject(filteredImage, forKey: cacheKey as NSURL)
            return filteredImage
        }
        return image
    }

    private func getImageFromZip(url: URL, cacheKey: URL) -> NSImage? {
        guard let zipArchive = currentZipArchive else { return nil }
        let index = images.firstIndex(of: url) ?? -1
        guard index >= 0 && index < archiveEntryPaths.count else { return nil }

        let entryPath = archiveEntryPaths[index]
        let pathComponents = entryPath.split(separator: "|")

        do {
            if pathComponents.count == 2 {
                let outerZipPath = String(pathComponents[0])
                let innerImagePath = String(pathComponents[1])
                if let nestedArchive = nestedArchives[outerZipPath],
                   let nestedEntry = nestedArchive[innerImagePath] {
                    var imageData = Data()
                    _ = try nestedArchive.extract(nestedEntry) { data in
                        imageData.append(data)
                    }
                    if let image = NSImage(data: imageData) {
                        if let filteredImage = applyFilter(to: image) {
                            imageCache.setObject(filteredImage, forKey: cacheKey as NSURL)
                            return filteredImage
                        }
                        return image
                    }
                }
            } else {
                guard let entry = zipImageEntries.first(where: { $0.path == entryPath }) else {
                    return nil
                }
                var imageData = Data()
                _ = try zipArchive.extract(entry) { data in
                    imageData.append(data)
                }
                if let image = NSImage(data: imageData) {
                    if let filteredImage = applyFilter(to: image) {
                        imageCache.setObject(filteredImage, forKey: cacheKey as NSURL)
                        return filteredImage
                    }
                    return image
                }
            }
        } catch {
            print("Error extracting image: \(error.localizedDescription)")
        }
        return nil
    }

    private func getImageFromFilesystem(url: URL, cacheKey: URL) -> NSImage? {
        if let image = NSImage(contentsOf: url) {
            if let filteredImage = applyFilter(to: image) {
                imageCache.setObject(filteredImage, forKey: cacheKey as NSURL)
                return filteredImage
            }
            return image
        }
        return nil
    }

    // MARK: - Private: Data management
    private func clearExistingData() {
        images = []
        currentIndex = 0
    }

    private func clearArchiveData() {
        currentZipArchive = nil
        zipImageEntries.removeAll()
        archiveFileURL = nil
        archiveEntryPaths.removeAll()
        imageCache.removeAllObjects()
        nestedArchives.removeAll()
        nestedImageEntries.removeAll()
        currentXADArchive = nil
        xadEntryIndices.removeAll()
        currentPDFDocument = nil
    }

    // MARK: - Private: ZIP loading (ZIPFoundation)
    private func loadImagesFromZip(url: URL) {
        do {
            currentZipArchive = nil
            imageCache.removeAllObjects()

            let archive = try Archive(url: url, accessMode: .read)
            currentZipArchive = archive
            archiveFileURL = url

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

            archiveEntryPaths = zipImageEntries.flatMap { entry -> [String] in
                if (entry.path as NSString).pathExtension.lowercased() == "zip",
                   let nestedEntries = nestedImageEntries[entry.path] {
                    return nestedEntries.map { "\(entry.path)|\($0.path)" }
                } else {
                    return [entry.path]
                }
            }

            DispatchQueue.main.async {
                self.images = self.archiveEntryPaths.indices.map { URL(fileURLWithPath: "zip://\($0)") }
                self.currentIndex = 0
            }
        } catch {
            print("Error loading ZIP file: \(error.localizedDescription)")
            ErrorUtil.showAlert(message: NSLocalizedString("Error loading ZIP file: \(error.localizedDescription)", comment: ""))
            DispatchQueue.main.async {
                self.images = []
                self.currentIndex = 0
            }
        }
    }

    // MARK: - Private: XAD archive loading (RAR, 7z, etc.)
    private func loadImagesFromXADArchive(url: URL, password: String? = nil) {
        do {
            imageCache.removeAllObjects()

            let reader = try XADArchiveReader(path: url.path)

            if let password = password {
                reader.setPassword(password)
            }

            // パスワードが必要だが未設定の場合
            if reader.isEncrypted && password == nil {
                DispatchQueue.main.async {
                    self.pendingPasswordURL = url
                    self.needsPassword = true
                }
                return
            }

            currentXADArchive = reader
            archiveFileURL = url

            var entryPaths: [String] = []
            var entryIndices: [Int] = []

            for i in 0..<reader.numberOfEntries {
                guard !reader.entryIsDirectory(at: i) else { continue }
                guard let name = reader.nameOfEntry(at: i) else { continue }

                let ext = (name as NSString).pathExtension.lowercased()
                guard imageExtensions.contains(ext) else { continue }

                // macOS メタデータを除外
                guard !name.hasPrefix("__MACOSX") else { continue }
                guard !(name as NSString).lastPathComponent.hasPrefix("._") else { continue }

                entryPaths.append(name)
                entryIndices.append(i)
            }

            // 自然順ソート（エントリパスとインデックスを同期）
            let sorted = zip(entryPaths, entryIndices)
                .sorted { $0.0.localizedStandardCompare($1.0) == .orderedAscending }
            archiveEntryPaths = sorted.map { $0.0 }
            xadEntryIndices = sorted.map { $0.1 }

            DispatchQueue.main.async {
                self.images = self.archiveEntryPaths.indices.map { URL(string: "xad://\($0)")! }
                self.currentIndex = 0
                self.updateCurrentImage()
            }
        } catch {
            print("Error loading archive: \(error.localizedDescription)")
            ErrorUtil.showAlert(message: String(format: NSLocalizedString("ErrorLoadingArchive", comment: ""), error.localizedDescription))
            DispatchQueue.main.async {
                self.images = []
                self.currentIndex = 0
            }
        }
    }

    // MARK: - Private: File/folder loading
    private func loadImagesFromFileOrFolder(url: URL) {
        imageCache.removeAllObjects()

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
                        if let selectedIndex = self.images.firstIndex(of: url) {
                            self.currentIndex = selectedIndex
                        } else {
                            self.currentIndex = 0
                        }
                    }
                }
                self.updateCurrentImage()
            }
        } catch {
            if (error as NSError).code == NSFileReadNoPermissionError {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("PermissionRequired", comment: "")
                    alert.informativeText = NSLocalizedString("PleaseCheckPermissionDialog", comment: "")
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.window.level = .floating
                    alert.runModal()
                }
                FileUtil.requestAccessForURL(folderURL) { success in
                    if success {
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
                        ErrorUtil.showAlert(message: NSLocalizedString("UnsupportedFileFormat", comment: ""))
                    }
                }
            }
        }
    }

    // MARK: - Private: Preloading
    private func preloadAdjacentImages() {
        guard !images.isEmpty else { return }

        let adjacentIndices = [
            max(0, currentIndex - 1),
            min(images.count - 1, currentIndex + 1)
        ]

        for index in adjacentIndices {
            guard index >= 0 && index < images.count else { continue }
            let url = images[index]
            let cacheKey = URL(string: "\(url.absoluteString)_\(currentFilter.rawValue)")!
            preloadQueue.async { [weak self] in
                guard let self = self else { return }
                if self.imageCache.object(forKey: cacheKey as NSURL) == nil {
                    if let image = self.loadImageFromSource(url: url) {
                        let finalImage = self.applyFilter(to: image) ?? image
                        self.imageCache.setObject(finalImage, forKey: cacheKey as NSURL)
                    }
                }
            }
        }
    }

    // MARK: - Private: Image info
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

        if archiveFileURL != nil && currentImageIndex < archiveEntryPaths.count {
            let archiveFileName = archiveFileURL?.lastPathComponent ?? ""
            let entryPath = archiveEntryPaths[currentImageIndex]
            let entryComponents = entryPath.split(separator: "|")
            let entryFileName = entryComponents.count > 1 ? String(entryComponents[1]) : (entryPath as NSString).lastPathComponent

            currentImageInfo = "\(archiveFileName) - \(entryFileName) (\(currentImageIndex + 1)/\(images.count))"
        } else {
            let folderPath = currentURL.deletingLastPathComponent().path
            let fileName = currentURL.lastPathComponent
            currentImageInfo = "\(folderPath)/\(fileName) (\(currentImageIndex + 1)/\(images.count))"
        }
    }

    private func loadImageFromSource(url: URL) -> NSImage? {
        if url.scheme == "xad" {
            guard let xadArchive = currentXADArchive else { return nil }
            let index = images.firstIndex(of: url) ?? -1
            guard index >= 0 && index < xadEntryIndices.count else { return nil }
            let entryIndex = xadEntryIndices[index]
            guard let data = xadArchive.contentsOfEntry(at: entryIndex) else { return nil }
            return NSImage(data: data)
        } else if currentZipArchive != nil && archiveFileURL != nil {
            return loadImageFromZip(url: url)
        } else {
            return NSImage(contentsOf: url)
        }
    }

    private func loadImageFromZip(url: URL) -> NSImage? {
        let index = images.firstIndex(of: url) ?? -1
        guard index >= 0 && index < archiveEntryPaths.count else { return nil }

        let entryPath = archiveEntryPaths[index]
        let pathComponents = entryPath.split(separator: "|")

        do {
            if pathComponents.count == 2 {
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

    // MARK: - Private: PDF
    private func loadPDF(url: URL) {
        if let pdfDocument = PDFDocument(url: url) {
            currentPDFDocument = pdfDocument
            let totalPDFPages = pdfDocument.pageCount
            images = (0..<totalPDFPages).map { URL(string: "pdf://\($0)")! }
            currentIndex = 0
            updateCurrentImage()
        } else {
            print("Failed to load PDF")
            ErrorUtil.showAlert(message: NSLocalizedString("FailedToLoadPDF", comment: ""))
        }
    }

    // MARK: - Private: Filter
    private func applyFilter(to image: NSImage) -> NSImage? {
        guard currentFilter != .none,
              let filterName = currentFilter.filterName,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: filterName) else { return image }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        for (key, value) in currentFilter.parameters {
            filter.setValue(value, forKey: key)
        }

        guard let outputImage = filter.outputImage,
              let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return NSImage(cgImage: cgOutput, size: image.size)
    }

    func updateFilter(_ filter: ImageFilter) {
        currentFilter = filter
        imageCache.removeAllObjects()
        objectWillChange.send()
    }
}
