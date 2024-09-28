import AppKit

struct KeyboardHandler {
    static func handleKeyPress(event: NSEvent, imageLoader: ImageLoader, appSettings: AppSettings) -> Bool {
        let isReversed = appSettings.isKeyboardDirectionReversed
        switch event.keyCode {
        case 123: // 左矢印キー
            isReversed ? imageLoader.showNextImage() : imageLoader.showPreviousImage()
            return true
        case 124: // 右矢印キー
            isReversed ? imageLoader.showPreviousImage() : imageLoader.showNextImage()
            return true
        default:
            return false
        }
    }
}