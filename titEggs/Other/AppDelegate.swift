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
import FacebookCore
import FBSDKCoreKit.FBSDKSettings
import FBSDKCoreKit


let buyPublisher = PassthroughSubject<Any, Never>()
var userID = ""

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
        
        if let deviceID = UIDevice.current.identifierForVendor?.uuidString {
            userID = deviceID
        }
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application( app,open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func fetchIDFA() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    Apphud.setDeviceIdentifiers(idfa: idfa, idfv: UIDevice.current.identifierForVendor?.uuidString)
                    Settings.shared.isAdvertiserTrackingEnabled = true
                   
                case .denied:
                    print("Tracking authorization denied by the user.")
                    Settings.shared.isAdvertiserTrackingEnabled = false
                   
                case .restricted:
                    print("Tracking is restricted (e.g., parental controls).")
                    Settings.shared.isAdvertiserTrackingEnabled = false
                   
                case .notDetermined:
                    print("Tracking authorization has not been determined.")
                    Settings.shared.isAdvertiserTrackingEnabled = false
                    
                @unknown default:
                    print("Unexpected tracking status.")
                    Settings.shared.isAdvertiserTrackingEnabled = true
                 
                    
                    
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


