import AppKit

struct KeyboardHandler {
    static func handleKeyPress(event: NSEvent, imageLoader: ImageLoader) -> Bool {
        if event.keyCode == 123 { // 左矢印キー
            imageLoader.showPreviousImage()
            return true
        } else if event.keyCode == 124 { // 右矢印キー
            imageLoader.showNextImage()
            return true
        }
        return false
    }
}