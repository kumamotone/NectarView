import Foundation
import AppKit
import SwiftUI
import NectarCore

class KeyboardHandler {
    private static let keyCodeUpArrow: UInt16 = 126
    private static let keyCodeDownArrow: UInt16 = 125
    private static let keyCodeLeftArrow: UInt16 = 123
    private static let keyCodeRightArrow: UInt16 = 124

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
        case keyCodeUpArrow:
            imageLoader.showPreviousImage()
            return nil
        case keyCodeDownArrow:
            imageLoader.showNextImage()
            return nil
        case keyCodeLeftArrow:
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
        case keyCodeRightArrow:
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
