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
import FacebookCore


class PurchaseManager: NSObject {
    
    let paywallID = "main" //айди пэйволла
    var productsApphud: [ApphudProduct] = [] //массив с продуктами

    
    override init() {
        super.init()
        
        Task {
            await self.loadPaywalls()
        }
        
    }
    
    //MARK: - Возврат true при наличии подписки
    var hasUnlockedPro: Bool {
        return Apphud.hasPremiumAccess()
    }
    

    //MARK: - Начало оплаты
    @MainActor func startPurchase(produst: ApphudProduct, escaping: @escaping(Bool) -> Void) {
        let selectedProduct = produst
        Apphud.purchase(selectedProduct) { result in
            if let error = result.error {
                debugPrint(error.localizedDescription)
               escaping(false)
            }
            debugPrint(result)
            if let subscription = result.subscription, subscription.isActive() {
                buyPublisher.send(1) //паблишер, который обновляет показ кнопки PRO на контроллерах. В его теле идет вызов hasUnlockedPro
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
    
    //MARK: - vосстановление покупок
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

    
//MARK: - загрузка продуктов с эппхад
    @MainActor
    func loadPaywalls() {
        Apphud.paywallsDidLoadCallback { paywalls, arg in
            if let paywall = paywalls.first(where: { $0.identifier == self.paywallID }) {
                Apphud.paywallShown(paywall)
                
                let products = paywall.products
                self.productsApphud = products
                for i in products {
                    print(i.skProduct?.subscriptionPeriod?.unit.rawValue, "Proddd")
                }
            }
        }
    }
    
    
  
}


