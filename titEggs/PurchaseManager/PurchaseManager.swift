//
//  PurchaseManager.swift
//  titEggs
//
//  Created by Владимир Кацап on 05.11.2024.
//

import Foundation
import StoreKit
import Combine

class PurchaseManager: NSObject {
    
    private var updates: Task<Void, Never>?
    
    private(set) var purchasedProductIDs = Set<String>()
    private let productIds = ["pro_lifetime", "pro_weekly"]
    var products: [Product] = []
    
    override init() {
        super.init()
        //SKPaymentQueue.default().add(self)
        updates = observeTransactionUpdates()
    }
    
    func loadProducts() async throws {
        self.products = try await Product.products(for: productIds)
    }
    
    var hasUnlockedPro: Bool {
        print(purchasedProductIDs)
        return !self.purchasedProductIDs.isEmpty
    }
    
    func updatePurchasedProducts() async {
        print(Transaction.currentEntitlements, "trasactions")
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                buyPublisher.send(1)
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
            print("Обновленные купленные продукты: \(self.purchasedProductIDs)")
        }
    }

    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }

    
    //оплата
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            //purchasedProductIDs.insert(transaction.productID)
            await self.updatePurchasedProducts()
            print("Покупка сделана")
        case .success(.unverified(_, let error)):
            print("Ошибка верификации покупки: \(error)")
        case .pending:
            print("Покупка находится в ожидании")
        case .userCancelled:
            print("Покупка отменена пользователем")
        @unknown default:
            break
        }
    }
    
    //vосстановление покупок
    func restoreArrPurchase() {
        Task {
            do {
                try await AppStore.sync()
            } catch {
                print(error)
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
}




