import AppKit

extension NSEvent {
    func matchesShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        return keyCode == shortcut.key.rawValue &&
            modifierFlags.standardizedFlags == shortcut.modifiers.nsFlags
    }
} 