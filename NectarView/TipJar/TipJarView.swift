import SwiftUI
import StoreKit

struct TipJarView: View {
    @StateObject private var store = TipJarStore()
    @Binding var isPresented: Bool
    @State private var showThankYou = false

    private let tipEmojis = ["☕", "🍰", "🍽️"]

    var body: some View {
        VStack(spacing: 20) {
            Text("🍯")
                .font(.system(size: 48))

            Text(NSLocalizedString("TipJar.Title", comment: ""))
                .font(.title2)
                .bold()

            Text(NSLocalizedString("TipJar.Description", comment: ""))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if store.isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if store.products.isEmpty {
                Text(NSLocalizedString("TipJar.Unavailable", comment: ""))
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(store.products.enumerated()), id: \.element.id) { index, product in
                        Button {
                            Task {
                                await store.purchase(product)
                            }
                        } label: {
                            HStack {
                                Text(tipEmojis[safe: index] ?? "🍯")
                                    .font(.title3)
                                Text(product.displayName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(product.displayPrice)
                                    .bold()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.quaternary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            if showThankYou {
                Text(NSLocalizedString("TipJar.ThankYou", comment: ""))
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .transition(.opacity)
            }

Button(NSLocalizedString("Close", comment: "")) {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 360)
        .task {
            await store.loadProducts()
        }
        .onChange(of: store.purchaseResult) {
            if case .success = store.purchaseResult {
                withAnimation {
                    showThankYou = true
                }
            }
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
