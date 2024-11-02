import XCTest
@testable import NectarView

class ImageLoaderTests: XCTestCase {
    var imageLoader: ImageLoader!
    var appSettings: AppSettings!

    override func setUp() {
        super.setUp()
        imageLoader = ImageLoader()
        appSettings = AppSettings()
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
        appSettings = nil
        super.tearDown()
    }

    func testSinglePageView() {
        // 単一ページ表示のテスト
        appSettings.isSpreadViewEnabled = false
        imageLoader.updateViewMode(appSettings: appSettings)
        imageLoader.updateCurrentImage()

        // 1. 通常の前後移動テスト
        XCTContext.runActivity(named: "通常の前後移動") { _ in
            imageLoader.currentIndex = 2
            XCTAssertEqual(imageLoader.currentImages.0, 2)
            XCTAssertNil(imageLoader.currentImages.1)

            imageLoader.showNextImage()
            XCTAssertEqual(imageLoader.currentImages.0, 3)
            XCTAssertNil(imageLoader.currentImages.1)

            imageLoader.showPreviousImage()
            XCTAssertEqual(imageLoader.currentImages.0, 2)
            XCTAssertNil(imageLoader.currentImages.1)
        }

        // 2. 最小値境界テスト
        XCTContext.runActivity(named: "最小値境界") { _ in
            imageLoader.currentIndex = 0
            imageLoader.showPreviousImage()
            XCTAssertEqual(imageLoader.currentImages.0, 0)
            XCTAssertNil(imageLoader.currentImages.1)
        }

        // 3. 最大値境界テスト
        XCTContext.runActivity(named: "最大値境界") { _ in
            imageLoader.currentIndex = 4
            imageLoader.showNextImage()
            XCTAssertEqual(imageLoader.currentImages.0, 4)
            XCTAssertNil(imageLoader.currentImages.1)
        }

        // 4. インデックスの一貫性テスト
        XCTContext.runActivity(named: "インデックスの一貫性") { _ in
            imageLoader.currentIndex = 2
            XCTAssertEqual(imageLoader.currentIndex, 2)
            XCTAssertEqual(imageLoader.currentImages.0, 2)
            XCTAssertNil(imageLoader.currentImages.1)
        }
    }

    func testSpreadView() {
        XCTContext.runActivity(named: "左から右への見開き表示") { _ in
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
            imageLoader.updateViewMode(appSettings: appSettings)
            imageLoader.currentIndex = 2

            XCTAssertEqual(imageLoader.currentImages.0, 2)
            XCTAssertEqual(imageLoader.currentImages.1, 3)
        }

        XCTContext.runActivity(named: "右から左への見開き表示") { _ in
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = true
            imageLoader.updateViewMode(appSettings: appSettings)
            imageLoader.currentIndex = 2

            XCTAssertEqual(imageLoader.currentImages.0, 3)
            XCTAssertEqual(imageLoader.currentImages.1, 2)
        }

        XCTContext.runActivity(named: "最後のページの表示") { _ in
            XCTContext.runActivity(named: "右から左への読み方") { _ in
                appSettings.isSpreadViewEnabled = true
                appSettings.isRightToLeftReading = true
                imageLoader.updateViewMode(appSettings: appSettings)
                imageLoader.currentIndex = 4

                XCTAssertNil(imageLoader.currentImages.0)
                XCTAssertEqual(imageLoader.currentImages.1, 4)
            }

            XCTContext.runActivity(named: "左から右への読み方") { _ in
                appSettings.isSpreadViewEnabled = true
                appSettings.isRightToLeftReading = false
                imageLoader.updateViewMode(appSettings: appSettings)
                imageLoader.currentIndex = 4

                XCTAssertEqual(imageLoader.currentImages.0, 4)
                XCTAssertNil(imageLoader.currentImages.1)
            }
        }
    }

    func testSpreadNavigation() {
        XCTContext.runActivity(named: "次の見開きに移動") { _ in
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
            imageLoader.updateViewMode(appSettings: appSettings)
            imageLoader.currentIndex = 0
            imageLoader.showNextImage()

            XCTAssertEqual(imageLoader.currentIndex, 2)
            XCTAssertEqual(imageLoader.currentImages.0, 2)
            XCTAssertEqual(imageLoader.currentImages.1, 3)
        }

        XCTContext.runActivity(named: "前の見開きに移動") { _ in
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
            imageLoader.updateViewMode(appSettings: appSettings)
            imageLoader.currentIndex = 4
            imageLoader.showPreviousImage()

            XCTAssertEqual(imageLoader.currentIndex, 2)
            XCTAssertEqual(imageLoader.currentImages.0, 2)
            XCTAssertEqual(imageLoader.currentImages.1, 3)
        }

        XCTContext.runActivity(named: "最初のページからの移動") { _ in
            XCTContext.runActivity(named: "右から左への読み方") { _ in
                appSettings.isSpreadViewEnabled = true
                appSettings.isRightToLeftReading = true
                imageLoader.updateViewMode(appSettings: appSettings)

                imageLoader.currentIndex = 0
                XCTAssertEqual(imageLoader.currentImages.0, 1)
                XCTAssertEqual(imageLoader.currentImages.1, 0)

                imageLoader.showPreviousImage()
                XCTAssertEqual(imageLoader.currentIndex, 0)
                XCTAssertEqual(imageLoader.currentImages.0, 1)
                XCTAssertEqual(imageLoader.currentImages.1, 0)
            }

            XCTContext.runActivity(named: "左から右への読み方") { _ in
                appSettings.isSpreadViewEnabled = true
                appSettings.isRightToLeftReading = false
                imageLoader.updateViewMode(appSettings: appSettings)
                imageLoader.currentIndex = 0

                XCTAssertEqual(imageLoader.currentImages.0, 0)
                XCTAssertEqual(imageLoader.currentImages.1, 1)

                imageLoader.showPreviousImage()
                XCTAssertEqual(imageLoader.currentIndex, 0)
                XCTAssertEqual(imageLoader.currentImages.0, 0)
                XCTAssertEqual(imageLoader.currentImages.1, 1)
            }
        }

        XCTContext.runActivity(named: "最後のページからの移動") { _ in
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
            imageLoader.updateViewMode(appSettings: appSettings)
            imageLoader.currentIndex = 4

            imageLoader.showNextImage()
            XCTAssertEqual(imageLoader.currentIndex, 4)
            XCTAssertEqual(imageLoader.currentImages.0, 4)
            XCTAssertNil(imageLoader.currentImages.1)
        }
    }

    func testEdgeCases() {
        XCTContext.runActivity(named: "画像が空の場合") { _ in
            imageLoader.images = []
            imageLoader.updateCurrentImage()

            XCTAssertNil(imageLoader.currentImages.0)
            XCTAssertNil(imageLoader.currentImages.1)
        }
    }

    func testImageFilters() {
        let imageLoader = ImageLoader()
        
        // フィルタなしの状態を確認
        XCTAssertEqual(imageLoader.currentFilter, .none)
        
        // フィルタを変更
        imageLoader.updateFilter(.sepia)
        XCTAssertEqual(imageLoader.currentFilter, .sepia)
        
        // フィルタをリセット
        imageLoader.updateFilter(.none)
        XCTAssertEqual(imageLoader.currentFilter, .none)
    }
}
