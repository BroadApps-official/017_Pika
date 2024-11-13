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

        
        Task {
            await self.loadPaywalls()
        }
        
    }
    
    
    var hasUnlockedPro: Bool {
        return Apphud.hasPremiumAccess()
    }
    

    //оплата
    
    @MainActor func startPurchase(produst: ApphudProduct, escaping: @escaping(Bool) -> Void) {
        let selectedProduct = produst
        Apphud.purchase(selectedProduct) { result in
            if let error = result.error {
                debugPrint(error.localizedDescription)
               escaping(false)
            }
            debugPrint(result)
            if let subscription = result.subscription, subscription.isActive() {
                buyPublisher.send(1)
                escaping(true)
            } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                buyPublisher.send(1)
                escaping(true)
            } else {
                if Apphud.hasActiveSubscription() {
                    buyPublisher.send(1)
                    escaping(true)
                }
            }
        }
    }
    
    //vосстановление покупок
    @MainActor func restorePurchase(escaping: @escaping(Bool) -> Void) {
        print("restore")
        Apphud.restorePurchases {  subscriptions, _, error in
            if let error = error {
                debugPrint(error.localizedDescription)
                escaping(false)
                buyPublisher.send(1)
            }
            if subscriptions?.first?.isActive() ?? false {
                buyPublisher.send(1)
                escaping(true)
                return
            }
            
            if Apphud.hasActiveSubscription() {
                escaping(true)
                buyPublisher.send(1)
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


