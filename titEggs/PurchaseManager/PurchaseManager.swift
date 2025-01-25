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
    
    let paywallID = "main" //айди пэйволла //ПОМЕНЯТЬ НА main
    var productsApphud: [ApphudProduct] = [] //массив с продуктами
    private let networking = NetWorking()

    
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
            
            print(result.success , "LDLDLLDLDLDLD")
            
            if result.success == false {
                escaping(false)
            }
            
            if let error = result.error {
                debugPrint(error.localizedDescription)
               escaping(false)
            }
            debugPrint(result)
            if let subscription = result.subscription, subscription.isActive() {
                self.fetchUserInfo { _ in
                    buyPublisher.send(1)
                    escaping(true)
                }
            } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                self.fetchUserInfo { _ in
                    buyPublisher.send(1)
                    escaping(true)
                }
            } else {
                if Apphud.hasActiveSubscription() {
                    buyPublisher.send(1)
                    escaping(true)
                }
            }
            
            
        }
    }
    
    //MARK: - vосстановление покупок
    @MainActor
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) {
        debugPrint("Restore started")
        
        Apphud.restorePurchases { subscriptions, _, error in
            if let error = error {
                debugPrint("Restore failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let subscription = subscriptions?.first, subscription.isActive() {
                debugPrint("Subscription restored and active: \(subscription.productId)")
                buyPublisher.send(1)
                completion(.success(true))
            } else if Apphud.hasActiveSubscription() {
                buyPublisher.send(1)
                debugPrint("Active subscription exists")
                completion(.success(true))
            } else {
                debugPrint("No active subscription found during restore")
                completion(.success(false))
            }
        }
    }

    
//MARK: - загрузка продуктов с эппхад
    @MainActor
    func loadPaywalls() {

        Apphud.paywallsDidLoadCallback { paywalls, arg in
           
            if let paywall = paywalls.first(where: { $0.identifier == self.paywallID}) {
                Apphud.paywallShown(paywall)
                
                //paywall.experimentName
                
                let products = paywall.products
                self.productsApphud = products
                
                print(products, "Proddd")
                for i in products {
                    print(i.productId, "ID")
                }
                
            }
        }
        
       
    }
    
    func fetchUserInfo(escaping: @escaping(Bool) -> Void) {
        networking.fetchUserInfo { isError, weekgen  in
            UserDefaults.standard.setValue("\(weekgen * 10)", forKey: "amountTokens")
            if weekgen == 0 {
                escaping(false)
            } else {
                escaping(true)
            }
        }
    }
    
    
    
    
  
}


