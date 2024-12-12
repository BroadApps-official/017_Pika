//
//  NetWorking.swift
//  titEggs
//
//  Created by Владимир Кацап on 07.11.2024.
//

import Foundation
import Alamofire

class NetWorking {
    
    func loadEffectsArr(escaping: @escaping(_ escaping: [Effect]) -> Void) {
           let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
           
           let header: HTTPHeaders = [(.authorization(bearerToken: token))]
        let parameters: Parameters = ["appName" : Bundle.main.bundleIdentifier ?? "com.agh.p1i1ka", "ai[0]": ["pika"], "ai[1]": ["pv"]]
           
           AF.request("https://vewapnew.online/api/templates", method: .get, parameters: parameters, headers: header).responseData { response in
               debugPrint(response, "dfsfdvffdv")
               switch response.result {
               case .success(let data):
                   do {
                       let effects = try JSONDecoder().decode(DataEffect.self, from: data)
                       escaping(effects.data)
                   } catch {
                       print("Ошибка декодирования JSON:", error.localizedDescription)
                       escaping([])
                   }
                   
               case  .failure(_):
                   escaping([])
               }
           }
       }
    
//    func loadPreviewVideo(idEffect: Int, escaping: @escaping (Data, Bool) -> Void) {
//        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
//        let headers: HTTPHeaders = [(.authorization(bearerToken: token))]
//        
//        let parameter: Parameters = ["appId" : Bundle.main.bundleIdentifier ?? "pika"]
//        
//        // Проверяем, есть ли видео в кэше
//        if let cachedData = loadCachedVideo(for: idEffect) {
//            // Если видео найдено в кэше, передаем его сразу
//            escaping(cachedData, false)
//            return
//        }
//        
//        // Выполняем сетевой запрос, если видео нет в кэше
//        AF.request("https://vewapnew.online/api/templates", method: .get, parameters: parameter, headers: headers).responseData { response in
//            debugPrint(response, "preview")
//            switch response.result {
//            case .success(let data):
//                do {
//                    let effects = try JSONDecoder().decode(DataEffect.self, from: data)
//                    let index = effects.data.firstIndex(where: { $0.id == idEffect }) ?? 1
//                    
//                    self.downloadVideo(from: effects.data[index].preview ?? "") { dataVideo, error in
//                        if let videoData = dataVideo, error == nil {
//                            self.cacheVideoData(videoData, for: idEffect)
//                            escaping(videoData, false)
//                        } else {
//                            escaping(Data(), true)
//                        }
//                    }
//                } catch {
//                    print("Ошибка декодирования JSON:", error.localizedDescription)
//                    escaping(Data(), true)
//                }
//                
//            case .failure(_):
//                escaping(Data(), true)
//            }
//        }
//    }
    
    
    
    func createVideo(data: Data, idEffect: String, escaping: @escaping (String) -> Void) {
        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
        
        let headers: HTTPHeaders = [(.authorization(bearerToken: token))]
        
        let param: Parameters = ["templateId": idEffect, "image" : data, "userId": userID, "appId": Bundle.main.bundleIdentifier ?? "pika"]
               
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(idEffect.utf8), withName: "templateId")
            multipartFormData.append(data, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
            multipartFormData.append(Data(userID.utf8), withName: "userId")
            multipartFormData.append(Data((Bundle.main.bundleIdentifier ?? "pika").utf8), withName: "appId")
        }, to: "https://vewapnew.online/api/generate", headers: headers)
        .responseData { response in
            debugPrint(response, "createOK")
            switch response.result {
            case .success(let data):
                do {
                    let effects = try JSONDecoder().decode(Generate.self, from: data)
//                    let amount = 100 - effects.data.totalWeekGenerations * 10
//                    if dynamicAppHud?.segment == "v2" {
//                        UserDefaults.standard.setValue("\(effects.data.maxGenerations)", forKey: "maxGenWeek")
//                        UserDefaults.standard.setValue("\(amount)", forKey: "amountTokens")
//                        UserDefaults.standard.synchronize()
//                    }
                    escaping(effects.data.generationId)
                } catch {
                    print("Ошибка декодирования JSON:", error.localizedDescription)
                    escaping("error")
                }
                
            case .failure(let error):
                print("Ошибка запроса:", error.localizedDescription)
                escaping("error")
            }
        }
    }
    
    
    //status & url
    func getStatus(itemId: String, escaping: @escaping(String, String) -> Void) {
        
        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
        
        let header: HTTPHeaders = [(.authorization(bearerToken: token)),
                                    HTTPHeader(name: "AppId", value: Bundle.main.bundleIdentifier ?? "pika")]
        let param: Parameters = ["generationId": itemId, "appId" : Bundle.main.bundleIdentifier ?? "pika"]

        
        AF.request("https://vewapnew.online/api/generationStatus", method: .get, parameters: param, headers: header).responseData { response in
            debugPrint(response, "statusGettttt")
            switch response.result {
            case .success(let data):
                do {
                    let item = try JSONDecoder().decode(Status.self, from: data)
//                    let amount = 100 - item.data.totalWeekGenerations * 10
//                    if dynamicAppHud?.segment == "v2" {
//                        UserDefaults.standard.setValue("\(item.data.maxGenerations)", forKey: "maxGenWeek")
//                        UserDefaults.standard.setValue("\(amount)", forKey: "amountTokens")
//                        UserDefaults.standard.synchronize()
//                    }
                    escaping(item.data.status, item.data.resultUrl ?? "")
                } catch {
                    print("Ошибка декодирования JSON:", error.localizedDescription)
                    escaping("fail", "fail")
                }
                
            case  .failure(_):
                escaping("fail", "fail")
            }
        }
        
    }
    

    func downloadVideo(from url: String, completion: @escaping (Data?, Error?) -> Void) {
        
        guard let videoURL = URL(string: url) else {
            completion(nil, NSError(domain: "Invalid URL", code: 400, userInfo: nil))
            return
        }

        AF.download(videoURL).responseData { response in
            debugPrint(response, "downloadssssss")
            switch response.result {
            case .success(let data):
                completion(data, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    
    private func cacheVideoData(_ data: Data, for idEffect: Int) {
        let cacheURL = getCacheURL(for: idEffect)
        do {
            try data.write(to: cacheURL)
            print("Видео сохранено в кэш: \(cacheURL)")
        } catch {
            print("Ошибка сохранения видео в кэш: \(error)")
        }
    }

    // Загрузка видео из кэша
    private func loadCachedVideo(for idEffect: Int) -> Data? {
        let cacheURL = getCacheURL(for: idEffect)
        return try? Data(contentsOf: cacheURL)
    }

    // Получение пути для кэширования видео
    private func getCacheURL(for idEffect: Int) -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDirectory.appendingPathComponent("video_\(idEffect).mp4")
    }
    
    func fetchUserInfo(escaping: @escaping(Bool, Int) -> Void) {
        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
        let param: Parameters = ["userId": userID, "bundleId": Bundle.main.bundleIdentifier ?? "com.agh.p1i1ka"]
        let headers: HTTPHeaders = [(.authorization(bearerToken: token))]
        
        AF.request("https://vewapnew.online/api/user", method: .get, parameters: param, headers: headers).responseData { response in
            debugPrint(response, "fetch")
            switch response.result {
            case .success(let data):
                do {
                    // Декодируем ответ
                    let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
                    let availableGenerations = userInfo.data.availableGenerations
                    print("Available Generations:", availableGenerations)
                    escaping(true, availableGenerations)
                } catch {
                    print("Ошибка декодирования JSON:", error.localizedDescription)
                    escaping(false, 0)
                }
            case .failure(let error):
                escaping(false, 0)
                print("Ошибка декодирования JSON:", error.localizedDescription)
            }
        }
    }
    
}

