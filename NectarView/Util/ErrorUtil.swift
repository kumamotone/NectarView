import AppKit

class ErrorUtil {
    static func handleLoadError(url: URL, error: Error, completion: @escaping () -> Void) {
        print("エラーが発生しました: \(error.localizedDescription)")
        print("問題のファイルパス: \(url.path)")
        
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSFileReadNoPermissionError:
                showAlert(message: "ファイルへのアクセス権限がありません。アプリケーションの権限設定を確認してください。\nファイルパス: \(url.path)")
            case NSFileReadUnknownError:
                showAlert(message: "ファイルの読み込みに失敗しました。ファイルが存在するか確認してください。\nファイルパス: \(url.path)")
            default:
                showAlert(message: "予期せぬエラーが発生しました: \(nsError.localizedDescription)\nファイルパス: \(url.path)")
            }
        }
        
        completion()
    }
    
    static func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "エラー"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
