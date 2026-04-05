import Foundation

class BookmarkManager {
    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "ImageBookmarks"

    func saveBookmarks(_ bookmarks: [Int], for url: URL) {
        var allBookmarks = getAllBookmarks()
        allBookmarks[url.path] = bookmarks
        userDefaults.set(allBookmarks, forKey: bookmarksKey)
    }

    func loadBookmarks(for url: URL) -> [Int] {
        let allBookmarks = getAllBookmarks()
        return allBookmarks[url.path] ?? []
    }

    private func getAllBookmarks() -> [String: [Int]] {
        return userDefaults.dictionary(forKey: bookmarksKey) as? [String: [Int]] ?? [:]
    }
}
