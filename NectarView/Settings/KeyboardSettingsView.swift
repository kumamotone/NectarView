import SwiftUI

struct KeyboardSettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @State private var isRecording = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    CustomizableShortcutRow(
                        title: "Next Page",
                        shortcut: appSettings.nextPageShortcut,
                        isRecording: $isRecording
                    ) { newShortcut in
                        appSettings.nextPageShortcut = newShortcut
                    }
                    CustomizableShortcutRow(
                        title: "Previous Page",
                        shortcut: appSettings.previousPageShortcut,
                        isRecording: $isRecording
                    ) { newShortcut in
                        appSettings.previousPageShortcut = newShortcut
                    }
                    KeyboardShortcutRow(title: "First Page", shortcut: "Home")
                    KeyboardShortcutRow(title: "Last Page", shortcut: "End")
                    KeyboardShortcutRow(title: "Add/Remove Bookmark", shortcut: "⌘B")
                    KeyboardShortcutRow(title: "Next Bookmark", shortcut: "⌘]")
                    KeyboardShortcutRow(title: "Previous Bookmark", shortcut: "⌘[")
                    KeyboardShortcutRow(title: "Show Bookmark List", shortcut: "⌘E")
                }
            }
        }
        .padding()
    }
}

struct KeyboardShortcutRow: View {
    let title: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(NSLocalizedString(title, comment: ""))
                .frame(width: 200, alignment: .leading)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
        }
    }
}

struct CustomizableShortcutRow: View {
    let title: String
    let shortcut: KeyboardShortcut
    @Binding var isRecording: Bool
    let onShortcutChange: (KeyboardShortcut) -> Void
    
    var body: some View {
        HStack {
            Text(NSLocalizedString(title, comment: ""))
                .frame(width: 200, alignment: .leading)
            Spacer()
            ShortcutRecorder(
                shortcut: shortcut,
                isRecording: $isRecording,
                onShortcutChange: onShortcutChange
            )
        }
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: KeyboardShortcut
    @Binding var isRecording: Bool
    let onShortcutChange: (KeyboardShortcut) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = RecorderView()
        view.shortcut = shortcut
        view.isRecording = isRecording
        view.onShortcutChange = onShortcutChange
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? RecorderView else { return }
        view.shortcut = shortcut
        view.isRecording = isRecording
    }
    
    class RecorderView: NSView {
        var shortcut: KeyboardShortcut = KeyboardShortcut(key: .rightArrow, modifiers: []) {
            didSet { updateButtonTitle() }
        }
        var isRecording: Bool = false {
            didSet { updateButtonTitle() }
        }
        var onShortcutChange: ((KeyboardShortcut) -> Void)?
        
        private let button = NSButton(title: "", target: nil, action: nil)
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupButton()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupButton()
        }
        
        private func setupButton() {
            button.bezelStyle = .rounded
            button.target = self
            button.action = #selector(handleButtonClick)
            addSubview(button)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: topAnchor),
                button.leadingAnchor.constraint(equalTo: leadingAnchor),
                button.trailingAnchor.constraint(equalTo: trailingAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            updateButtonTitle()
        }
        
        @objc private func handleButtonClick() {
            isRecording.toggle()
            updateButtonTitle()
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }
        
        private func updateButtonTitle() {
            button.title = isRecording ? "Recording..." : shortcut.displayString
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            handleKeyEvent(event)
        }
        
        override func keyUp(with event: NSEvent) {
            handleKeyEvent(event)
        }
        
        private func handleKeyEvent(_ event: NSEvent) {
            guard isRecording else {
                super.keyDown(with: event)
                return
            }
            
            if event.keyCode == 53 { // ESC
                isRecording = false
                return
            }
            
            if let key = Key(rawValue: event.keyCode) {
                let newShortcut = KeyboardShortcut(
                    key: key,
                    modifiers: event.modifierFlags.standardizedFlags
                )
                
                shortcut = newShortcut
                isRecording = false
                onShortcutChange?(newShortcut)
            }
        }
    }
} 