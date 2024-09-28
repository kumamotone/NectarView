import AppKit

struct KeyboardHandler {
    static func handleKeyPress(event: NSEvent, imageLoader: ImageLoader) -> Bool {
        switch event.keyCode {
        case 123, 126: // 左矢印キーまたは上矢印キー
            imageLoader.showPreviousImage()
            return true
        case 124, 125: // 右矢印キーまたは下矢印キー
            imageLoader.showNextImage()
            return true
        default:
            return false
        }
    }
}