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
import Alamofire
import Firebase
import FacebookCore
import FBSDKCoreKit.FBSDKSettings
import FBSDKCoreKit
import OneSignalFramework


let buyPublisher = PassthroughSubject<Any, Never>()
var userID = ""
var dynamicAppHud: DynamicSegment?

var appVersion = "1.15"

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        getAppStoreVersion()
        
        Apphud.start(apiKey: "app_Ya3A7cxvYehiiDp7nq6MARXH8adoTQ")
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: UIDevice.current.identifierForVendor?.uuidString)
        fetchIDFA()
        getCampaign(apphudUserID: Apphud.userID())
        OneSignal.initialize("48593fbd-dce5-4723-9261-b1d0b23a4666", withLaunchOptions:  launchOptions)
        OneSignal.login(Apphud.userID())
        
        FirebaseApp.configure()
        
        var open = UserDefaults.standard.integer(forKey: "count")
        open += 1
        UserDefaults.standard.setValue(open, forKey: "count")
        
        userID = Apphud.userID()
        
      //  print(Apphud.userID(), "IDDDDDDDD USER", userID)
       // print(dynamicAppHud?.segment, "segments")
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
    
    //MARK: - при сегменте V2 - у нас появляются ограничения на генерации.  code - id эксперемента, нужен для вывода количества продуктов
    
    func getCampaign(apphudUserID: String) {
        
        let param = ["appHudUserId" : apphudUserID]
        
        AF.request("https://testerapps.site/api/campaign/c2f8IRxxdiiSKt7", method: .post, parameters: param).responseData{ response in
            debugPrint(response, "авторизация ок")
            switch response.result {
            case .success(let data):
                do {
                    let items = try JSONDecoder().decode([DynamicSegment].self, from: data)
                    
                    for i in items {
                        if i.code == "pika_pay" {
                            dynamicAppHud = i
                        }
                    }
                } catch {
                    print("Ошибка декодирования JSON:", error.localizedDescription)
                }
                
            case  .failure(_):
                print("fail")
            }
        }
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
    
    private func getAppStoreVersion() {
        let appID = "6737900240" // Замените на ваш идентификатор приложения в App Store
        let urlString = "https://itunes.apple.com/lookup?id=\(appID)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching app store version: \(error)")
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                // Парсим данные JSON
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = jsonResponse["results"] as? [[String: Any]],
                   let appInfo = results.first,
                   let version = appInfo["version"] as? String {
                    appVersion = version
                    print(version, "sdfgsd")
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        
        task.resume()
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


struct DynamicSegment: Decodable {
    var code: String
    var segment: String
    var forceSegment: String?
}
