import SwiftUI

class AppSettings: ObservableObject {
    @Published var backgroundColor: Color {
        didSet {
            UserDefaults.standard.setColor(backgroundColor, forKey: "backgroundColor")
        }
    }
    @Published var controlBarColor: Color {
        didSet {
            UserDefaults.standard.setColor(controlBarColor, forKey: "controlBarColor")
        }
    }
    
    @Published var isSpreadViewEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSpreadViewEnabled, forKey: "isSpreadViewEnabled")
        }
    }
    @Published var isRightToLeftReading: Bool {
        didSet {
            UserDefaults.standard.set(isRightToLeftReading, forKey: "isRightToLeftReading")
        }
    }
    @Published var isLeftRightKeyReversed: Bool {
        didSet {
            UserDefaults.standard.set(isLeftRightKeyReversed, forKey: "isLeftRightKeyReversed")
        }
    }
    @Published var isUpDownKeyReversed: Bool {
        didSet {
            UserDefaults.standard.set(isUpDownKeyReversed, forKey: "isUpDownKeyReversed")
        }
    }
    
    init() {
        self.backgroundColor = UserDefaults.standard.color(forKey: "backgroundColor") ?? .black
        self.controlBarColor = UserDefaults.standard.color(forKey: "controlBarColor") ?? Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.4)
        self.isSpreadViewEnabled = UserDefaults.standard.bool(forKey: "isSpreadViewEnabled")
        self.isRightToLeftReading = UserDefaults.standard.bool(forKey: "isRightToLeftReading")
        self.isLeftRightKeyReversed = UserDefaults.standard.bool(forKey: "isLeftRightKeyReversed", defaultValue: true)
        self.isUpDownKeyReversed = UserDefaults.standard.bool(forKey: "isUpDownKeyReversed")
    }
    
    func resetToDefaults() {
        backgroundColor = .black
        controlBarColor = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.4)
        isSpreadViewEnabled = false
        isRightToLeftReading = false
        isLeftRightKeyReversed = true
        isUpDownKeyReversed = false
    }
}

extension UserDefaults {
    func setColor(_ color: Color, forKey key: String) {
        let components = NSColor(color).cgColor.components
        set(components, forKey: key)
    }
    
    func color(forKey key: String) -> Color? {
        guard let components = object(forKey: key) as? [CGFloat], components.count >= 3 else {
            return nil
        }
        return Color(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
    
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
}
