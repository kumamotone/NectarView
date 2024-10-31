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
        // ページ移動
        if event.matchesShortcut(appSettings.nextPageShortcut) {
            if appSettings.isSpreadViewEnabled && appSettings.isRightToLeftReading {
                imageLoader.showPreviousImage()
            } else {
                imageLoader.showNextImage()
            }
            return nil
        }
        
        if event.matchesShortcut(appSettings.previousPageShortcut) {
            if appSettings.isSpreadViewEnabled && appSettings.isRightToLeftReading {
                imageLoader.showNextImage()
            } else {
                imageLoader.showPreviousImage()
            }
            return nil
        }

        // ブックマーク操作
        if event.matchesShortcut(appSettings.addBookmarkShortcut) {
            imageLoader.toggleBookmark()
            return nil
        }
        
        if event.matchesShortcut(appSettings.nextBookmarkShortcut) {
            imageLoader.goToNextBookmark()
            return nil
        }
        
        if event.matchesShortcut(appSettings.previousBookmarkShortcut) {
            imageLoader.goToPreviousBookmark()
            return nil
        }

        // ズーム操作
        if event.matchesShortcut(appSettings.zoomInShortcut) {
            appSettings.zoomFactor *= 1.25
            return nil
        }
        
        if event.matchesShortcut(appSettings.zoomOutShortcut) {
            appSettings.zoomFactor *= 0.8
            return nil
        }
        
        if event.matchesShortcut(appSettings.resetZoomShortcut) {
            appSettings.zoomFactor = 1.0
            return nil
        }

        // 他のキー操作（上下矢印は従来通り）
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
