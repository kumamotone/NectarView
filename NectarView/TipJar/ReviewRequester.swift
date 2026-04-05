import Foundation

enum ReviewRequester {
    private static let fileOpenCountKey = "reviewFileOpenCount"
    private static let lastReviewRequestKey = "reviewLastRequestDate"
    private static let minimumFileOpens = 5
    private static let minimumDaysBetweenRequests = 90

    static func recordFileOpen() {
        let count = UserDefaults.standard.integer(forKey: fileOpenCountKey)
        UserDefaults.standard.set(count + 1, forKey: fileOpenCountKey)
    }

    /// Checks conditions and posts a notification if a review should be requested.
    /// The notification is handled by the SwiftUI view that has access to `requestReview`.
    static func requestReviewIfNeeded() {
        let fileOpens = UserDefaults.standard.integer(forKey: fileOpenCountKey)
        guard fileOpens >= minimumFileOpens else { return }

        if let lastRequest = UserDefaults.standard.object(forKey: lastReviewRequestKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
            guard daysSince >= minimumDaysBetweenRequests else { return }
        }

        UserDefaults.standard.set(Date(), forKey: lastReviewRequestKey)
        NotificationCenter.default.post(name: .requestAppReview, object: nil)
    }
}

extension Notification.Name {
    static let requestAppReview = Notification.Name("requestAppReview")
}
