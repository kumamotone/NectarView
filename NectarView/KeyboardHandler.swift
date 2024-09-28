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
                imageLoader.showPreviousSpreadSimple()
            } else {
                imageLoader.showPreviousImage()
            }
            return true
        case 125: // 下矢印キー
            if isSpreadView {
                imageLoader.showNextSpreadSimple()
            } else {
                imageLoader.showNextImage()
            }
            return true
        case 123: // 左矢印キー
            if isLeftRightReversed {
                if isSpreadView {
                    imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
                } else {
                    imageLoader.showNextImage()
                }
            } else {
                if isSpreadView {
                    imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
                } else {
                    imageLoader.showPreviousImage()
                }
            }
            return true
        case 124: // 右矢印キー
            if isLeftRightReversed {
                if isSpreadView {
                    imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
                } else {
                    imageLoader.showPreviousImage()
                }
            } else {
                if isSpreadView {
                    imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
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
