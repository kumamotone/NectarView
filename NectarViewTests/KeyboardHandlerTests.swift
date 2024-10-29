import XCTest
@testable import NectarView

final class KeyboardHandlerTests: XCTestCase {
    private var mockImageLoader: MockImageLoader!
    private var appSettings: AppSettings!
    
    override func setUp() {
        super.setUp()
        mockImageLoader = MockImageLoader()
        appSettings = AppSettings()
    }
    
    override func tearDown() {
        mockImageLoader = nil
        appSettings = nil
        super.tearDown()
    }
    
    // MARK: - 上下キーのテスト（常に同じ動作）
    func test上キーは常に前のページに移動すること() {
        let event = createKeyEvent(keyCode: 126)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    func test下キーは常に次のページに移動すること() {
        let event = createKeyEvent(keyCode: 125)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
    }
    
    // MARK: - 左キーのテスト（4パターン）
    func test左キー_単ページモードで通常の場合は前のページに移動すること() {
        appSettings.isSpreadViewEnabled = false
        appSettings.useLeftKeyToGoNextWhenSinglePage = false
        let event = createKeyEvent(keyCode: 123)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    func test左キー_単ページモードで左キーを次へ進む設定の場合は次のページに移動すること() {
        appSettings.isSpreadViewEnabled = false
        appSettings.useLeftKeyToGoNextWhenSinglePage = true
        let event = createKeyEvent(keyCode: 123)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
    }
    
    func test左キー_見開きモードで左から右読みの場合は前のページに移動すること() {
        appSettings.isSpreadViewEnabled = true
        appSettings.isRightToLeftReading = false
        let event = createKeyEvent(keyCode: 123)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    func test左キー_見開きモードで右から左読みの場合は次のページに移動すること() {
        appSettings.isSpreadViewEnabled = true
        appSettings.isRightToLeftReading = true
        let event = createKeyEvent(keyCode: 123)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
    }
    
    // MARK: - 右キーのテスト（4パターン）
    func test右キー_単ページモードで通常の場合は次のページに移動すること() {
        appSettings.isSpreadViewEnabled = false
        appSettings.useLeftKeyToGoNextWhenSinglePage = false
        let event = createKeyEvent(keyCode: 124)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
    }
    
    func test右キー_単ページモードで左キーを次へ進む設定の場合は前のページに移動すること() {
        appSettings.isSpreadViewEnabled = false
        appSettings.useLeftKeyToGoNextWhenSinglePage = true
        let event = createKeyEvent(keyCode: 124)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    func test右キー_見開きモードで左から右読みの場合は次のページに移動すること() {
        appSettings.isSpreadViewEnabled = true
        appSettings.isRightToLeftReading = false
        let event = createKeyEvent(keyCode: 124)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
    }
    
    func test右キー_見開きモードで右から左読みの場合は前のページに移動すること() {
        appSettings.isSpreadViewEnabled = true
        appSettings.isRightToLeftReading = true
        let event = createKeyEvent(keyCode: 124)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    private func createKeyEvent(keyCode: UInt16) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown,
                        location: .zero,
                        modifierFlags: [],
                        timestamp: 0,
                        windowNumber: 0,
                        context: nil,
                        characters: "",
                        charactersIgnoringModifiers: "",
                        isARepeat: false,
                        keyCode: keyCode)!
    }
}

private class MockImageLoader: ImageLoader {
    var showNextImageCallCount = 0
    var showPreviousImageCallCount = 0
    
    override func showNextImage() {
        showNextImageCallCount += 1
    }
    
    override func showPreviousImage() {
        showPreviousImageCallCount += 1
    }
} 
