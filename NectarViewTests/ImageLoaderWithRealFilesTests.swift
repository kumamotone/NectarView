import XCTest
@testable import NectarView

final class ImageLoaderWithRealFilesTests: XCTestCase {
    var imageLoader: ImageLoader!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        imageLoader = ImageLoader()
    }
    
    override func tearDownWithError() throws {
        imageLoader = nil
        try super.tearDownWithError()
    }
    
    func testLoadImagesFromFile() throws {
        let bundle = Bundle(for: type(of: self))
        guard let testFolderPath = bundle.path(forResource: "image1", ofType: "png")?
            .components(separatedBy: "image1.png").first else {
            XCTFail("テストデータが見つかりません")
            return
        }
        
        let testFolderURL = URL(fileURLWithPath: testFolderPath)
        
        // フォルダから画像を読み込む
        imageLoader.loadImages(from: testFolderURL)
        
        // メインスレッドでの処理を待機
        let expectation = XCTestExpectation(description: "画像の読み込み")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // 検証
        let fileNames = imageLoader.images.map { $0.lastPathComponent }.sorted()
        XCTAssertEqual(fileNames, ["image1.png", "image2.png", "image3.png"])
    }
    
    func testLoadImagesFromZipFile() throws {
        let bundle = Bundle(for: type(of: self))
        guard let testDataZipURL = bundle.url(forResource: "TestData", withExtension: "zip") else {
            XCTFail("TestData.zipが見つかりません")
            return
        }
        
        // ZIPファイルから画像を読み込む
        imageLoader.loadImages(from: testDataZipURL)
        
        // メインスレッドでの処理を待機
        let expectation = XCTestExpectation(description: "画像の読み込み")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // 検証
        let fileNames = imageLoader.images.enumerated().map { index, url in 
            imageLoader.getDisplayName(for: url, at: index)
        }.sorted()
        XCTAssertEqual(fileNames, ["image1.png", "image2.png", "image3.png"])
    }
} 
