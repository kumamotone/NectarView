// Colorを@AppStorageで保存できるようにする
// https://zenn.dev/kyome/articles/3f6ee868c52b15

import SwiftUI

extension NSColor {
    var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = .zero
        var g: CGFloat = .zero
        var b: CGFloat = .zero
        var a: CGFloat = .zero
        if let color = self.usingColorSpace(.sRGB) {
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
        return (r, g, b, a)
    }
}

extension Color {
    var rgbaValues: (red: Double, green: Double, blue: Double, opacity: Double) {
        let rgba = NSColor(self).rgba
        return (rgba.red, rgba.green, rgba.blue, rgba.alpha)
    }
}

extension Color: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        let components = rawValue.components(separatedBy: ",")
        let r = Double(components[0]) ?? .zero
        let g = Double(components[1]) ?? .zero
        let b = Double(components[2]) ?? .zero
        let o = Double(components[3]) ?? .zero
        self = .init(.sRGB, red: r, green: g, blue: b, opacity: o)
    }

    public var rawValue: String {
        let rgba = self.rgbaValues
        let r = String(format: "%0.8f", rgba.red)
        let g = String(format: "%0.8f", rgba.green)
        let b = String(format: "%0.8f", rgba.blue)
        let o = String(format: "%0.8f", rgba.opacity)
        return [r, g, b, o].joined(separator: ",")
    }
}
