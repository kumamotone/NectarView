import StoreKit

@MainActor
class TipJarStore: ObservableObject {
    static let productIDs: [String] = [
        "dev.kuma.NectarView.tip.small",
        "dev.kuma.NectarView.tip.medium",
        "dev.kuma.NectarView.tip.large"
    ]

    @Published var products: [Product] = []
    @Published var purchasedIDs: Set<String> = []
    @Published var isLoading = false
    @Published var purchaseResult: PurchaseResult?

    private var transactionListener: Task<Void, Never>?

    enum PurchaseResult: Equatable {
        case success
        case cancelled
        case error(String)
    }

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: Self.productIDs)
            self.products = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }

        await updatePurchasedProducts()
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchasedIDs.insert(product.id)
                purchaseResult = .success
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

    func isPurchased(_ product: Product) -> Bool {
        purchasedIDs.contains(product.id)
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        purchasedIDs = purchased
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
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
