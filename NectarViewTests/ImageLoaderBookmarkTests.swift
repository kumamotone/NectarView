import XCTest
@testable import NectarView

class ImageLoaderBookmarkTests: XCTestCase {
    var imageLoader: ImageLoader!
    
    override func setUp() {
        super.setUp()
        imageLoader = ImageLoader()
    }
    
    override func tearDown() {
        imageLoader = nil
        super.tearDown()
    }
    
    func testToggleBookmark() {
        let urls = [URL(fileURLWithPath: "/test1.jpg")]
        imageLoader.images = urls
        
        XCTAssertFalse(imageLoader.isCurrentPageBookmarked())
        
        imageLoader.toggleBookmark()
        XCTAssertTrue(imageLoader.isCurrentPageBookmarked())
        
        imageLoader.toggleBookmark()
        XCTAssertFalse(imageLoader.isCurrentPageBookmarked())
    }
    
    func testBookmarkNavigation() {
        let urls = [
            URL(fileURLWithPath: "/test1.jpg"),
            URL(fileURLWithPath: "/test2.jpg"),
            URL(fileURLWithPath: "/test3.jpg"),
            URL(fileURLWithPath: "/test4.jpg")
        ]
        imageLoader.images = urls
        
        // ブックマークを設定
        imageLoader.currentIndex = 1
        imageLoader.toggleBookmark()
        imageLoader.currentIndex = 3
        imageLoader.toggleBookmark()
        
        // 現在位置から次のブックマークへ
        imageLoader.currentIndex = 0
        imageLoader.goToNextBookmark()
        XCTAssertEqual(imageLoader.currentIndex, 1)
        
        imageLoader.goToNextBookmark()
        XCTAssertEqual(imageLoader.currentIndex, 3)
        
        // 前のブックマークへ
        imageLoader.goToPreviousBookmark()
        XCTAssertEqual(imageLoader.currentIndex, 1)
    }
} 