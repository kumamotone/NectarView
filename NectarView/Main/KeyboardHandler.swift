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
        // 次のページ
        if event.matchesShortcut(appSettings.nextPageShortcut) {
            if appSettings.isSpreadViewEnabled && appSettings.isRightToLeftReading {
                imageLoader.showPreviousImage()
            } else {
                imageLoader.showNextImage()
            }
            return nil
        }
        
        // 前のページ
        if event.matchesShortcut(appSettings.previousPageShortcut) {
            if appSettings.isSpreadViewEnabled && appSettings.isRightToLeftReading {
                imageLoader.showNextImage()
            } else {
                imageLoader.showPreviousImage()
            }
            return nil
        }

        // 他のキー操作
        switch event.keyCode {
        case Key.upArrow.rawValue:
            imageLoader.showPreviousImage()
            return nil
            
        case Key.downArrow.rawValue:
            imageLoader.showNextImage()
            return nil
            
        default:
            return event
        }
    }
}
