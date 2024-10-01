import AppKit
import UniformTypeIdentifiers

class FileUtil {
    static func requestAccessForURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = url
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.prompt = NSLocalizedString("Allow Access to Folder", comment: "")
        openPanel.message = NSLocalizedString("Access permission is required to display images in this folder.", comment: "")

        openPanel.begin { result in
            completion(result == .OK && openPanel.url != nil)
        }
    }

    static func openFile(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.folder, .image, .archive]

        panel.begin { result in
            if result == .OK {
                completion(panel.url)
            } else {
                completion(nil)
            }
        }
    }
}
