//
//  PurchaseManager.swift
//  titEggs
//
//  Created by Владимир Кацап on 05.11.2024.
//

import Foundation
import StoreKit
import Combine
import ApphudSDK


class PurchaseManager: NSObject {
    
    let paywallID = "main"
    
    private var updates: Task<Void, Never>?
    
    private(set) var purchasedProductIDs = Set<String>()
    private let productIds = ["pro_lifetime", "pro_weekly"]
    var productsApphud: [ApphudProduct] = []

    
    override init() {
        super.init()
        //SKPaymentQueue.default().add(self)
        updates = observeTransactionUpdates()
        
        Task {
            await self.loadPaywalls()
        }
        
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
    
    @MainActor func startPurchase(produst: ApphudProduct) {
        let selectedProduct = produst
        Apphud.purchase(selectedProduct) { [weak self] result in
            if let error = result.error {
                debugPrint(error.localizedDescription)
                // подписка не активка либо другая ошибка - обработка ошибку
            }
            debugPrint(result)
            if let subscription = result.subscription, subscription.isActive() {
                // подписка активка -> можно закрыть пейвол
            } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                // подписка активка -> можно закрыть пейвол
            } else {
                if Apphud.hasActiveSubscription() {
                    // подписка активка -> можно закрыть пейвол
                }
            }
        }
    }
    
    //vосстановление покупок
    @MainActor func restorePurchase() {
        print("restore")
        Apphud.restorePurchases {  subscriptions, _, error in
            if let error = error {
                debugPrint(error.localizedDescription)
                // подписка не активка либо другая ошибка - обработка ошибку
            }
            if subscriptions?.first?.isActive() ?? false {
                // подписка активка -> можно закрыть пейвол
                return
            }
            
            if Apphud.hasActiveSubscription() {
                // подписка активка -> можно закрыть пейвол
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    

    @MainActor
    func loadPaywalls() {
        Apphud.paywallsDidLoadCallback { paywalls, arg in
            if let paywall = paywalls.first(where: { $0.identifier == self.paywallID }) {
                Apphud.paywallShown(paywall)
                
                let products = paywall.products
                self.productsApphud = products
                for i in products {
                    print(i.skProduct?.productIdentifier, "ProdID")
                    print(i.skProduct?.price.stringValue, "cena")
                }
 
            }
        }
    }

    
    
    
    
}


