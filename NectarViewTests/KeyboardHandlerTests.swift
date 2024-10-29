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
    
    func testUpArrowKeyPressShouldShowPreviousImage() {
        let event = createKeyEvent(keyCode: 126)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    func testDownArrowKeyPressShouldShowNextImage() {
        let event = createKeyEvent(keyCode: 125)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
    }
    
    func testLeftArrowKeyPressWithDefaultSettings() {
        let event = createKeyEvent(keyCode: 123)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 0)
    }
    
    func testRightArrowKeyPressWithDefaultSettings() {
        let event = createKeyEvent(keyCode: 124)
        _ = KeyboardHandler.handleKeyPress(event: event, imageLoader: mockImageLoader, appSettings: appSettings)
        
        XCTAssertEqual(mockImageLoader.showNextImageCallCount, 1)
        XCTAssertEqual(mockImageLoader.showPreviousImageCallCount, 0)
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
