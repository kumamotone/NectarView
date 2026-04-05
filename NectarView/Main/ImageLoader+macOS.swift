import Foundation
import AppKit
import NectarCore
import XADMasterSwift

/// macOS-specific XAD archive support for ImageLoader.
/// Sets up closure-based injection so NectarCore's ImageLoader can handle RAR/7z/etc.
extension ImageLoader {
    /// Call this on app launch to enable XAD archive support.
    func setupXADSupport() {
        xadArchiveLoader = { [weak self] url, password in
            self?.loadImagesFromXADArchive(url: url, password: password)
        }
        xadImageGetter = { [weak self] url, index, xadEntryIndices in
            self?.getImageFromXAD(url: url, index: index, xadEntryIndices: xadEntryIndices)
        }
        errorHandler = { message in
            ErrorUtil.showAlert(message: message)
        }
        fileOpenHandler = { completion in
            FileUtil.openFile(completion: completion)
        }
    }

    // MARK: - XAD Archive Loading

    private func loadImagesFromXADArchive(url: URL, password: String? = nil) {
        do {
            let reader = try XADArchiveReader(path: url.path)

            if let password = password {
                reader.setPassword(password)
            }

            if reader.isEncrypted && password == nil {
                DispatchQueue.main.async {
                    self.setPendingPasswordURL(url)
                    self.needsPassword = true
                }
                return
            }

            var entryPaths: [String] = []
            var entryIndices: [Int] = []

            for i in 0..<reader.numberOfEntries {
                guard !reader.entryIsDirectory(at: i) else { continue }
                guard let name = reader.nameOfEntry(at: i) else { continue }

                let ext = (name as NSString).pathExtension.lowercased()
                guard imageExtensions.contains(ext) else { continue }
                guard !name.hasPrefix("__MACOSX") else { continue }
                guard !(name as NSString).lastPathComponent.hasPrefix("._") else { continue }

                entryPaths.append(name)
                entryIndices.append(i)
            }

            let sorted = zip(entryPaths, entryIndices)
                .sorted { $0.0.localizedStandardCompare($1.0) == .orderedAscending }
            let sortedPaths = sorted.map { $0.0 }
            let sortedIndices = sorted.map { $0.1 }

            // Store the reader for later image retrieval
            _currentXADArchive = reader

            let images = sortedPaths.indices.map { URL(string: "xad://\($0)")! }
            setArchiveData(
                images: images,
                archiveFileURL: url,
                archiveEntryPaths: sortedPaths,
                xadEntryIndices: sortedIndices
            )
        } catch {
            print("Error loading archive: \(error.localizedDescription)")
            ErrorUtil.showAlert(message: String(format: NSLocalizedString("ErrorLoadingArchive", comment: ""), error.localizedDescription))
            DispatchQueue.main.async {
                self.images = []
            }
        }
    }

    // MARK: - XAD Image Retrieval

    private func getImageFromXAD(url: URL, index: Int, xadEntryIndices: [Int]) -> PlatformImage? {
        guard let xadArchive = _currentXADArchive else { return nil }
        guard index >= 0 && index < xadEntryIndices.count else { return nil }

        let entryIndex = xadEntryIndices[index]
        guard let data = xadArchive.contentsOfEntry(at: entryIndex) else { return nil }
        return NSImage(data: data)
    }

    // MARK: - XAD Archive Storage (associated object)

    private static var xadArchiveKey: UInt8 = 0

    private var _currentXADArchive: XADArchiveReader? {
        get {
            objc_getAssociatedObject(self, &Self.xadArchiveKey) as? XADArchiveReader
        }
        set {
            objc_setAssociatedObject(self, &Self.xadArchiveKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
