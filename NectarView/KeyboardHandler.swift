import Foundation
import AppKit

class KeyboardHandler {
    static func handleKeyPress(event: NSEvent, imageLoader: ImageLoader, appSettings: AppSettings) -> Bool {
        switch event.keyCode {
        case 123, 124: // 左矢印キー、右矢印キー
            let isNext = (event.keyCode == 123) != appSettings.isLeftRightKeyReversed
            if appSettings.isSpreadViewEnabled {
                if isNext {
                    imageLoader.showNextSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
                } else {
                    imageLoader.showPreviousSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
                }
            } else {
                if isNext {
                    imageLoader.showNextImage()
                } else {
                    imageLoader.showPreviousImage()
                }
            }
            return true
        case 125, 126: // 下矢印キー、上矢印キー
            let isNext = (event.keyCode == 126) != appSettings.isUpDownKeyReversed
            if appSettings.isSpreadViewEnabled {
                if isNext {
                    imageLoader.showNextSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
                } else {
                    imageLoader.showPreviousSpread(isRightToLeftReading: appSettings.isRightToLeftReading)
                }
            } else {
                if isNext {
                    imageLoader.showNextImage()
                } else {
                    imageLoader.showPreviousImage()
                }
            }
            return true
        default:
            return false
        }
    }
}