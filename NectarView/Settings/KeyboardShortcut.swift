import Foundation
import AppKit
import Carbon

struct KeyboardShortcut: Codable {
    let key: Key
    let modifiers: ModifierFlags
    
    var displayString: String {
        var parts: [String] = []
        
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        
        parts.append(key.displayString)
        
        return parts.joined(separator: "")
    }
    
    init(key: Key, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = ModifierFlags(rawValue: modifiers.rawValue)
    }
}

enum Key: UInt16, Codable {
    // 文字キー
    case a = 0
    case s = 1
    case d = 2
    case f = 3
    case h = 4
    case g = 5
    case z = 6
    case x = 7
    case c = 8
    case v = 9
    case b = 11
    case q = 12
    case w = 13
    case e = 14
    case r = 15
    case y = 16
    case t = 17
    case one = 18
    case two = 19
    case three = 20
    case four = 21
    case six = 22
    case five = 23
    case equal = 24
    case nine = 25
    case seven = 26
    case minus = 27
    case eight = 28
    case zero = 29
    case rightBracket = 30
    case o = 31
    case u = 32
    case leftBracket = 33
    case i = 34
    case p = 35
    case return_key = 36
    case l = 37
    case j = 38
    case quote = 39
    case k = 40
    case semicolon = 41
    case backslash = 42
    case comma = 43
    case slash = 44
    case n = 45
    case m = 46
    case period = 47
    case tab = 48
    case space = 49
    case grave = 50
    case delete = 51
    
    // ファンクションキー
    case f1 = 122
    case f2 = 120
    case f3 = 99
    case f4 = 118
    case f5 = 96
    case f6 = 97
    case f7 = 98
    case f8 = 100
    case f9 = 101
    case f10 = 109
    case f11 = 103
    case f12 = 111
    
    // 特殊キー
    case escape = 53
    case home = 115
    case pageUp = 116
    case delete_forward = 117
    case end = 119
    case pageDown = 121
    case leftArrow = 123
    case rightArrow = 124
    case downArrow = 125
    case upArrow = 126
    
    var displayString: String {
        switch self {
        // 文字キー
        case .a: return "A"
        case .s: return "S"
        case .d: return "D"
        case .f: return "F"
        case .h: return "H"
        case .g: return "G"
        case .z: return "Z"
        case .x: return "X"
        case .c: return "C"
        case .v: return "V"
        case .b: return "B"
        case .q: return "Q"
        case .w: return "W"
        case .e: return "E"
        case .r: return "R"
        case .y: return "Y"
        case .t: return "T"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .zero: return "0"
        case .equal: return "="
        case .minus: return "-"
        case .rightBracket: return "]"
        case .o: return "O"
        case .u: return "U"
        case .leftBracket: return "["
        case .i: return "I"
        case .p: return "P"
        case .return_key: return "⏎"
        case .l: return "L"
        case .j: return "J"
        case .quote: return "'"
        case .k: return "K"
        case .semicolon: return ";"
        case .backslash: return "\\"
        case .comma: return ","
        case .slash: return "/"
        case .n: return "N"
        case .m: return "M"
        case .period: return "."
        case .tab: return "⇥"
        case .space: return "Space"
        case .grave: return "`"
        case .delete: return "⌫"
        
        // ファンクションキー
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        
        // 特殊キー
        case .escape: return "⎋"
        case .home: return "Home"
        case .pageUp: return "Page Up"
        case .delete_forward: return "⌦"
        case .end: return "End"
        case .pageDown: return "Page Down"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .downArrow: return "↓"
        case .upArrow: return "↑"
        }
    }
}

struct ModifierFlags: OptionSet, Codable {
    let rawValue: UInt
    
    static let command = ModifierFlags(rawValue: 1 << 0)
    static let option = ModifierFlags(rawValue: 1 << 1)
    static let control = ModifierFlags(rawValue: 1 << 2)
    static let shift = ModifierFlags(rawValue: 1 << 3)
    
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    init(_ nsFlags: NSEvent.ModifierFlags) {
        var rawValue: UInt = 0
        if nsFlags.contains(.command) { rawValue |= ModifierFlags.command.rawValue }
        if nsFlags.contains(.option) { rawValue |= ModifierFlags.option.rawValue }
        if nsFlags.contains(.control) { rawValue |= ModifierFlags.control.rawValue }
        if nsFlags.contains(.shift) { rawValue |= ModifierFlags.shift.rawValue }
        self.rawValue = rawValue
    }
    
    var nsFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) { flags.insert(.command) }
        if contains(.option) { flags.insert(.option) }
        if contains(.control) { flags.insert(.control) }
        if contains(.shift) { flags.insert(.shift) }
        return flags
    }
}

extension NSEvent.ModifierFlags {
    var standardizedFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) { flags.insert(.command) }
        if contains(.option) { flags.insert(.option) }
        if contains(.control) { flags.insert(.control) }
        if contains(.shift) { flags.insert(.shift) }
        return flags
    }
}
