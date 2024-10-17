import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("NectarView Help", comment: ""))
                    .font(.largeTitle)
                    .padding(.bottom)
                
                HelpSection(title: NSLocalizedString("Getting Started", comment: ""), content: NSLocalizedString("Drag and drop image files, PDF files, or ZIP archives onto the application window to open them. Alternatively, use the 'Open' option from the File menu or press Command+O to select files.", comment: ""))
                
                HelpSection(title: NSLocalizedString("Navigation", comment: ""), content: NSLocalizedString("• Use left and right arrow keys to switch between images.\n• Use the mouse wheel or trackpad to scroll.\n• Press spacebar to toggle fullscreen mode.\n• Double-click to toggle window size between fit-to-screen and actual size.", comment: ""))
                
                HelpSection(title: NSLocalizedString("View Modes", comment: ""), content: NSLocalizedString("• Single Page View (Command+1): Displays one page at a time.\n• Spread View (Right to Left) (Command+2): Displays two pages side by side, right page first.\n• Spread View (Left to Right) (Command+3): Displays two pages side by side, left page first.", comment: ""))
                
                HelpSection(title: NSLocalizedString("Zoom and Rotate", comment: ""), content: NSLocalizedString("• Zoom In: Command++\n• Zoom Out: Command+-\n• Reset Zoom: Command+0\n• Rotate 90° Clockwise: Command+R\n• Rotate 90° Counterclockwise: Command+L", comment: ""))
                
                HelpSection(title: NSLocalizedString("Bookmarks", comment: ""), content: NSLocalizedString("• Add/Remove Bookmark: Command+B\n• Go to Next Bookmark: Command+]\n• Go to Previous Bookmark: Command+[\n• Show Bookmark List: Command+E", comment: ""))
                
                HelpSection(title: NSLocalizedString("Auto Page Turn", comment: ""), content: NSLocalizedString("Enable auto page turn in the settings menu. Adjust the interval to set how quickly pages turn automatically.", comment: ""))
                
                HelpSection(title: NSLocalizedString("Customization", comment: ""), content: NSLocalizedString("Access the Settings menu (Command+,) to customize:\n• Background color\n• Control bar color\n• Reading direction\n• Keyboard shortcuts\n• Language preference", comment: ""))
                
                HelpSection(title: NSLocalizedString("Supported File Formats", comment: ""), content: NSLocalizedString("NectarView supports the following file formats:\n• Images: PNG, JPEG, GIF, BMP, TIFF, WebP\n• Archives: ZIP\n• Documents: PDF", comment: ""))
                
                HelpSection(title: NSLocalizedString("Keyboard Shortcuts", comment: ""), content: NSLocalizedString("• Open File: Command+O\n• Close Window: Command+W\n• Quit Application: Command+Q\n• Toggle Fullscreen: Command+Control+F\n• Show Settings: Command+,", comment: ""))
            }
            .padding()
        }
    }
}

struct HelpSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
    }
}

#Preview {
    HelpView()
}
