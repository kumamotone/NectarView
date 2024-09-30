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
            if isSpreadView {
                if isLeftRightReversed {
                    imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
                } else {
                    imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
                }
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
                if isLeftRightReversed {
                    imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
                } else {
                    imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
                }
            } else {
                if isLeftRightReversed {
                    imageLoader.showPreviousImage()
                } else {
                    imageLoader.showNextImage()
                }
            }
            return true
        case 22: // 6キー
            imageLoader.toggleViewMode(.spreadRightToLeft)
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = true
            return true
        case 26: // 7キー
            imageLoader.toggleViewMode(.spreadLeftToRight)
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
            return true
        case 28: // 8キー
            imageLoader.toggleViewMode(.single)
            appSettings.isSpreadViewEnabled = false
            return true
        default:
            return false
        }
    }
}
