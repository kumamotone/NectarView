import AppKit

class ErrorUtil {
    static func handleLoadError(url: URL, error: Error, completion: @escaping () -> Void) {
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoPermissionError:
                showAlert(message: NSLocalizedString("You don't have permission to access this file. Please check the application's permission settings.", comment: "") + "\n" + NSLocalizedString("Problem file path: %@", comment: "").replacingOccurrences(of: "%@", with: url.path))
            case NSFileReadUnknownError:
                showAlert(message: NSLocalizedString("Failed to read the file. Please make sure the file exists.", comment: "") + "\n" + NSLocalizedString("Problem file path: %@", comment: "").replacingOccurrences(of: "%@", with: url.path))
            default:
                showAlert(message: NSLocalizedString("An unexpected error occurred: %@", comment: "").replacingOccurrences(of: "%@", with: nsError.localizedDescription) + "\n" + NSLocalizedString("Problem file path: %@", comment: "").replacingOccurrences(of: "%@", with: url.path))
            }
        }

        completion()
    }

    static func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Error", comment: "")
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
    }
}
