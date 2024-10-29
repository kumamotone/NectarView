import Foundation
import AppKit
import SwiftUI

class KeyboardHandler {
    static func setupKeyboardHandler(imageLoader: ImageLoader, appSettings: AppSettings) {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(event: event, imageLoader: imageLoader, appSettings: appSettings)
        }
    }

    static func handleKeyPress(event: NSEvent, imageLoader: ImageLoader, appSettings: AppSettings) -> NSEvent? {
        let useLeftKeyToGoNextWhenSinglePage = appSettings.useLeftKeyToGoNextWhenSinglePage
        let isSpreadView = appSettings.isSpreadViewEnabled
        let isRightToLeftReading = appSettings.isRightToLeftReading

        switch event.keyCode {
        case 126: // 上矢印キー
            imageLoader.showPreviousImage()
            return nil
        case 125: // 下矢印キー
            imageLoader.showNextImage()
            return nil
        case 123: // 左矢印キー
            if isSpreadView {
                if isRightToLeftReading {
                    imageLoader.showNextImage()
                } else {
                    imageLoader.showPreviousImage()
                }
            } else {
                if useLeftKeyToGoNextWhenSinglePage {
                    imageLoader.showNextImage()
                } else {
                    imageLoader.showPreviousImage()
                }
            }
            return nil
        case 124: // 右矢印キー
            if isSpreadView {
                if isRightToLeftReading {
                    imageLoader.showPreviousImage()
                } else {
                    imageLoader.showNextImage()
                }
            } else {
                if useLeftKeyToGoNextWhenSinglePage {
                    imageLoader.showPreviousImage()
                } else {
                    imageLoader.showNextImage()
                }
            }
            return nil
        default:
            return event
        }
    }
}
