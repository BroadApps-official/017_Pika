//
//  AppDelegate.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import StoreKit
import Combine
import ApphudSDK
import AppTrackingTransparency
import AdSupport
import AlamofireNetworkActivityLogger
import Firebase

let buyPublisher = PassthroughSubject<Any, Never>()


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Apphud.start(apiKey: "app_Ya3A7cxvYehiiDp7nq6MARXH8adoTQ")
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: UIDevice.current.identifierForVendor?.uuidString)
        fetchIDFA()
        
        FirebaseApp.configure()
        
        
        var open = UserDefaults.standard.integer(forKey: "count")
        open += 1
        UserDefaults.standard.setValue(open, forKey: "count")
       
        
        return true
    }
    
    func fetchIDFA() {
            if #available(iOS 14.5, *) {
                DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                    ATTrackingManager.requestTrackingAuthorization { status in
                        guard status == .authorized else {return}
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                        Apphud.setDeviceIdentifiers(idfa: idfa, idfv: UIDevice.current.identifierForVendor?.uuidString)
                    }
                }
            }
        }
    
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

