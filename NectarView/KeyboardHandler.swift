import Foundation
import AppKit

class KeyboardHandler {
    static func handleKeyPress(event: NSEvent, imageLoader: ImageLoader, appSettings: AppSettings) -> Bool {
        let isLeftRightReversed = appSettings.isLeftRightKeyReversed
        let isSpreadView = appSettings.isSpreadViewEnabled
        let isRightToLeftReading = appSettings.isRightToLeftReading

        switch event.keyCode {
        case 126: // 上矢印キー
            if isSpreadView {
                imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
            } else {
                imageLoader.showPreviousImage()
            }
            return true
        case 125: // 下矢印キー
            if isSpreadView {
                imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
            } else {
                imageLoader.showNextImage()
            }
            return true
        case 123: // 左矢印キー
            if isSpreadView {
                imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
            } else {
                if isLeftRightReversed {
                    imageLoader.showNextImage()
                } else {
                    imageLoader.showPreviousImage()
                }
            }
            return true
        case 124: // 右矢印キー
            if isSpreadView {
                imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
            } else {
                if isLeftRightReversed {
                    imageLoader.showPreviousImage()
                } else {
                    imageLoader.showNextImage()
                }
            }
            return true
        default:
            return false
        }
    }
}
