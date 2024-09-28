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
                showPrevious(imageLoader: imageLoader, isSpreadView: true, isRightToLeftReading: isRightToLeftReading)
            } else {
                imageLoader.showPreviousImage()
            }
            return true
        case 125: // 下矢印キー
            if isSpreadView {
                showNext(imageLoader: imageLoader, isSpreadView: true, isRightToLeftReading: isRightToLeftReading)
            } else {
                imageLoader.showNextImage()
            }
            return true
        case 123: // 左矢印キー
            if isSpreadView {
                if isRightToLeftReading {
                    showNext(imageLoader: imageLoader, isSpreadView: true, isRightToLeftReading: isRightToLeftReading)
                } else {
                    showPrevious(imageLoader: imageLoader, isSpreadView: true, isRightToLeftReading: isRightToLeftReading)
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
                if isRightToLeftReading {
                    showPrevious(imageLoader: imageLoader, isSpreadView: true, isRightToLeftReading: isRightToLeftReading)
                } else {
                    showNext(imageLoader: imageLoader, isSpreadView: true, isRightToLeftReading: isRightToLeftReading)
                }
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

    private static func showNext(imageLoader: ImageLoader, isSpreadView: Bool, isRightToLeftReading: Bool) {
        if isSpreadView {
            imageLoader.showNextSpread(isRightToLeftReading: isRightToLeftReading)
        } else {
            imageLoader.showNextImage()
        }
    }

    private static func showPrevious(imageLoader: ImageLoader, isSpreadView: Bool, isRightToLeftReading: Bool) {
        if isSpreadView {
            imageLoader.showPreviousSpread(isRightToLeftReading: isRightToLeftReading)
        } else {
            imageLoader.showPreviousImage()
        }
    }
}
