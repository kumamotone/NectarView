import XCTest
@testable import NectarView

class ImageLoaderTests: XCTestCase {
    var imageLoader: ImageLoader!

    override func setUp() {
        super.setUp()
        imageLoader = ImageLoader()
        // テスト用の画像URLを設定
        imageLoader.images = [
            URL(string: "file:///image1.jpg")!,
            URL(string: "file:///image2.jpg")!,
            URL(string: "file:///image3.jpg")!,
            URL(string: "file:///image4.jpg")!,
            URL(string: "file:///image5.jpg")!
        ]
    }

    override func tearDown() {
        imageLoader = nil
        super.tearDown()
    }

    func testSinglePageView() {
        // 単一ページ表示のテスト
        imageLoader.updateSpreadIndices(isSpreadViewEnabled: false, isRightToLeftReading: false)
        
        // 1. 通常の前後移動テスト
        XCTContext.runActivity(named: "通常の前後移動") { _ in
            imageLoader.currentIndex = 2
            XCTAssertEqual(imageLoader.currentImageURL, URL(string: "file:///image3.jpg")!)
            
            imageLoader.showNextImage()
            XCTAssertEqual(imageLoader.currentImageURL, URL(string: "file:///image4.jpg")!)

            imageLoader.showPreviousImage()
            XCTAssertEqual(imageLoader.currentImageURL, URL(string: "file:///image3.jpg")!)
        }
        
        // 2. 最小値境界テスト
        XCTContext.runActivity(named: "最小値境界") { _ in
            imageLoader.currentIndex = 0
            imageLoader.showPreviousImage()
            XCTAssertEqual(imageLoader.currentImageURL, URL(string: "file:///image1.jpg")!)
        }

        // 3. 最大値境界テスト
        XCTContext.runActivity(named: "最大値境界") { _ in
            imageLoader.currentIndex = 4
            imageLoader.showNextImage()
            XCTAssertEqual(imageLoader.currentImageURL, URL(string: "file:///image5.jpg")!)
        }
        
        // 4. インデックスの一貫性テスト
        XCTContext.runActivity(named: "インデックスの一貫性") { _ in
            imageLoader.currentIndex = 2
            XCTAssertEqual(imageLoader.currentIndex, 2)
            XCTAssertEqual(imageLoader.currentImageURL, URL(string: "file:///image3.jpg")!)
        }
    }

    func testSpreadView() {
        XCTContext.runActivity(named: "左から右への見開き表示") { _ in
            imageLoader.currentIndex = 2
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
            
            XCTAssertEqual(imageLoader.currentSpreadIndices.0, 2)
            XCTAssertEqual(imageLoader.currentSpreadIndices.1, 3)
        }

        XCTContext.runActivity(named: "右から左への見開き表示") { _ in
            imageLoader.currentIndex = 2
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: true)
            
            XCTAssertEqual(imageLoader.currentSpreadIndices.0, 3)
            XCTAssertEqual(imageLoader.currentSpreadIndices.1, 2)
        }

        XCTContext.runActivity(named: "最後のページの表示") { _ in
            imageLoader.currentIndex = 4

            XCTContext.runActivity(named: "右から左への読み方") { _ in
                imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: true)
                
                XCTAssertEqual(imageLoader.currentSpreadIndices.0, 4)
                XCTAssertNil(imageLoader.currentSpreadIndices.1)
            }

            XCTContext.runActivity(named: "左から右への読み方") { _ in
                imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
                
                XCTAssertEqual(imageLoader.currentSpreadIndices.0, 4)
                XCTAssertNil(imageLoader.currentSpreadIndices.1)
            }
        }
    }

    func testSpreadNavigation() {
        XCTContext.runActivity(named: "次の見開きに移動") { _ in
            imageLoader.currentIndex = 0
            imageLoader.showNextSpread(isRightToLeftReading: false)
            
            XCTAssertEqual(imageLoader.currentIndex, 2)
            XCTAssertEqual(imageLoader.currentSpreadIndices.0, 2)
            XCTAssertEqual(imageLoader.currentSpreadIndices.1, 3)
        }

        XCTContext.runActivity(named: "前の見開きに移動") { _ in
            imageLoader.currentIndex = 4
            imageLoader.showPreviousSpread(isRightToLeftReading: false)
            
            XCTAssertEqual(imageLoader.currentIndex, 2)
            XCTAssertEqual(imageLoader.currentSpreadIndices.0, 2)
            XCTAssertEqual(imageLoader.currentSpreadIndices.1, 3)
        }
        
        XCTContext.runActivity(named: "最初のページからの移動") { _ in
            XCTContext.runActivity(named: "右から左への読み方") { _ in
                imageLoader.currentIndex = 0
                imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: true)
                imageLoader.showPreviousSpread(isRightToLeftReading: true)
                
                XCTAssertEqual(imageLoader.currentIndex, 0)
                XCTAssertEqual(imageLoader.currentSpreadIndices.0, 1)
                XCTAssertEqual(imageLoader.currentSpreadIndices.1, 0)
            }

            XCTContext.runActivity(named: "左から右への読み方") { _ in
                imageLoader.currentIndex = 0
                imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
                imageLoader.showPreviousSpread(isRightToLeftReading: false)
                
                XCTAssertEqual(imageLoader.currentIndex, 0)
                XCTAssertEqual(imageLoader.currentSpreadIndices.0, 0)
                XCTAssertEqual(imageLoader.currentSpreadIndices.1, 1)
            }
        }

        XCTContext.runActivity(named: "最後のページからの移動") { _ in
            imageLoader.currentIndex = 4
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
            imageLoader.showNextSpread(isRightToLeftReading: false)
            
            XCTAssertEqual(imageLoader.currentIndex, 4)
            XCTAssertEqual(imageLoader.currentSpreadIndices.0, 4)
            XCTAssertNil(imageLoader.currentSpreadIndices.1)
        }
    }

    func testEdgeCases() {
        XCTContext.runActivity(named: "画像が空の場合") { _ in
            imageLoader.images = []
            imageLoader.updateSpreadIndices(isSpreadViewEnabled: true, isRightToLeftReading: false)
            
            XCTAssertNil(imageLoader.currentSpreadIndices.0)
            XCTAssertNil(imageLoader.currentSpreadIndices.1)
        }
    }

    func testCurrentImageInfo() {
        // TODO: loadImages をスタブして頑張るべき
        XCTContext.runActivity(named: "画像ファイルがロードされた場合") { _ in
            imageLoader.images = [URL(string: "file:///Users/test/Documents/image1.jpg")!]
            imageLoader.updateCurrentFolderAndFileName(url: URL(string: "file:///Users/test/Documents/image1.jpg")!) // should be called
            imageLoader.currentIndex = 0
            XCTAssertEqual(imageLoader.currentImageInfo, "/Users/test/Documents/image1.jpg (1/1)")
        }

        XCTContext.runActivity(named: "ZIPファイルがロードされた場合") { _ in
            imageLoader.images = [URL(string: "file:///Users/test/Documents/archive.zip/image1.jpg")!]
            imageLoader.currentIndex = 0
            imageLoader.currentZipFileName = "archive.zip"
            imageLoader.currentZipEntryFileName = "image1.jpg"
            XCTAssertEqual(imageLoader.currentImageInfo, "archive.zip - image1.jpg (1/1)")
        }

        XCTContext.runActivity(named: "画像がロードされていない場合") { _ in
            imageLoader.images = []
            imageLoader.currentZipFileName = nil // should be called
            imageLoader.currentZipEntryFileName = nil // should be called
            XCTAssertEqual(imageLoader.currentImageInfo, NSLocalizedString("NectarView", comment: "NectarView"))
        }
    }
}
