import StoreKit

@MainActor
class TipJarStore: ObservableObject {
    static let productIDs: [String] = [
        "dev.kuma.NectarView.tip.small.c2",
        "dev.kuma.NectarView.tip.medium.c",
        "dev.kuma.NectarView.tip.large.c"
    ]

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var purchaseResult: PurchaseResult?

    enum PurchaseResult: Equatable {
        case success
        case cancelled
        case error(String)
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("[TipJarStore] Loading products for IDs: \(Self.productIDs)")
            let products = try await Product.products(for: Self.productIDs)
            print("[TipJarStore] Loaded \(products.count) products: \(products.map { $0.id })")
            self.products = products.sorted { $0.price < $1.price }
        } catch {
            print("[TipJarStore] Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseResult = .success
                ReviewRequester.requestReviewIfNeeded()
            case .userCancelled:
                purchaseResult = .cancelled
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseResult = .error(error.localizedDescription)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
