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
    
    init() {
        self.backgroundColor = UserDefaults.standard.color(forKey: "backgroundColor") ?? .black
        self.controlBarColor = UserDefaults.standard.color(forKey: "controlBarColor") ?? Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.4)
    }
    
    func resetToDefaults() {
        self.backgroundColor = .black
        self.controlBarColor = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.4)
        
        UserDefaults.standard.removeObject(forKey: "backgroundColor")
        UserDefaults.standard.removeObject(forKey: "controlBarColor")
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
}
