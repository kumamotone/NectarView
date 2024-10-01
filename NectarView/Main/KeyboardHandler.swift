import Foundation
import AppKit
import SwiftUI

class KeyboardHandler {
    static func setupKeyboardHandler(for contentView: ContentView) {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(event: event, contentView: contentView)
        }
    }

    private static func handleKeyPress(event: NSEvent, contentView: ContentView) -> NSEvent? {
        let imageLoader = contentView.imageLoader
        let appSettings = contentView.appSettings
        let isLeftRightReversed = appSettings.isLeftRightKeyReversed
        let isSpreadView = appSettings.isSpreadViewEnabled
        let isRightToLeftReading = appSettings.isRightToLeftReading

        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "+", "=":
                contentView.zoom(by: 1.25)
                return nil
            case "-":
                contentView.zoom(by: 0.8)
                return nil
            case "0":
                contentView.resetZoom()
                return nil
            default:
                break
            }
        }

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
                if isLeftRightReversed {
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
                if isLeftRightReversed {
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
