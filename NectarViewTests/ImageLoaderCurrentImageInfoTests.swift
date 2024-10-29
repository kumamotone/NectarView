import XCTest
@testable import NectarView

final class ImageLoaderCurrentImageInfoTests: XCTestCase {
    var imageLoader: ImageLoader!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        imageLoader = ImageLoader()
    }
    
    override func tearDownWithError() throws {
        imageLoader = nil
        try super.tearDownWithError()
    }
    
    func testCurrentImageInfo() {
        XCTContext.runActivity(named: "画像がロードされていない場合") { _ in
            imageLoader.images = []
            XCTAssertEqual(imageLoader.currentImageInfo, NSLocalizedString("NectarView", comment: "NectarView"))
            XCTAssertEqual(imageLoader.currentImageInfo, "NectarView")
        }

        XCTContext.runActivity(named: "画像ファイルが読み込まれている場合") { _ in
            imageLoader.images = [URL(string: "file:///Users/test/Documents/image1.jpg")!]
            imageLoader.currentIndex = 0
            imageLoader.updateCurrentImage()
            XCTAssertEqual(imageLoader.currentImageInfo, "/Users/test/Documents/image1.jpg (1/1)")
        }

        XCTContext.runActivity(named: "ZIPファイルがロードされた場合") { _ in
            imageLoader.images = [URL(string: "file:///Users/test/Documents/archive.zip/image1.jpg")!]
            imageLoader.currentIndex = 0
            imageLoader.zipFileURL = URL(string: "file:///Users/test/Documents/archive.zip")!
            imageLoader.zipEntryPaths = ["image1.jpg"]
            imageLoader.updateCurrentImage()
            XCTAssertEqual(imageLoader.currentImageInfo, "archive.zip - image1.jpg (1/1)")
        }
    }
}
