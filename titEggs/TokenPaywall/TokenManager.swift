//
//  TokenManager.swift
//  titEggs
//
//  Created by Владимир Кацап on 09.12.2024.
//

import Foundation
import StoreKit
import Combine
import ApphudSDK
import FacebookCore
import Alamofire

class TokenManager: NSObject {
    
    let paywallID = "tokens"
    var productsApphud: [ApphudProduct] = []
    
    
    
    @MainActor
    func startPurchase(product: ApphudProduct, escaping: @escaping (Bool) -> Void) {
        Apphud.purchase(product) { result in
            if let error = result.error {
                debugPrint("Ошибка покупки: \(error.localizedDescription)")
                escaping(false)
            } else if result.success {
                if let nonRenewingPurchase = result.nonRenewingPurchase {
                    debugPrint("покупка успешна: \(nonRenewingPurchase.productId)")
                    escaping(true)
                } else {
                    debugPrint("Покупка успешна, но покупка не обнаружена")
                    escaping(false)
                }
            } else {
                debugPrint("Покупка не прошла")
                escaping(false)
            }
        }
    }

    
    @MainActor
    func loadPaywalls(escaping: @escaping() -> Void) {

        Apphud.paywallsDidLoadCallback { paywalls, arg in
           
            if let paywall = paywalls.first(where: { $0.identifier == self.paywallID}) {
                Apphud.paywallShown(paywall)
                
                paywall.experimentName
                
                let products = paywall.products
                self.productsApphud = products
                
                print(products, "Proddd")
                for i in products {
                    print(i.productId, "ID")
                }
                escaping()
            }
        }
        
       
    }
    
//    func buyTokens(gen: Int, escaping: @escaping() -> Void) {
//        
//        print(gen, "jvsjdn")
//        
//        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
//        let param: Parameters = ["userId": userID, "bundleId": Bundle.main.bundleIdentifier ?? "com.agh.p1i1ka", "generations": gen]
//        let headers: HTTPHeaders = [(.authorization(bearerToken: token))]
//        
//        print(param, "parameters")
//        
//        AF.request("https://vewapnew.online/api/user", method: .post, parameters: param, headers: headers).responseData { response in
//            debugPrint(response, "token")
//            switch response.result {
//            case .success(let data):
//                do {
//                    let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
//                    let availableGenerations = userInfo.data.availableGenerations
//                    print("Available Generations:", availableGenerations)
//                    UserDefaults.standard.setValue("\(availableGenerations * 10)", forKey: "amountTokens")
//                    escaping()
//                } catch {
//                    print("Ошибка декодирования JSON:", error.localizedDescription)
//                    escaping()
//                }
//            case .failure(let error):
//                escaping()
//            }
//        }
//    }
    
}
