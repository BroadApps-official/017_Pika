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
//        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
//        
//        let header: HTTPHeaders = [(.authorization(bearerToken: token))]
//        
//        AF.request("https://vewapnew.online/api/templates", method: .get, headers: header).responseData { response in
//            switch response.result {
//            case .success(let data):
//                do {
//                    let effects = try JSONDecoder().decode(DataEffect.self, from: data)
//                    escaping(effects.data)
//                } catch {
//                    print("Ошибка декодирования JSON:", error.localizedDescription)
//                    escaping([])
//                }
//                
//            case  .failure(_):
//                escaping([])
//            }
//        }
        
        let arr =  [Effect(id: 1, effect: "Levitate"), Effect(id: 2, effect: "Decapitate"), Effect(id: 3, effect: "Eye-pop"), Effect(id: 4, effect: "Inflate"), Effect(id: 5, effect: "Melt"), Effect(id: 6, effect: "Explode"), Effect(id: 7, effect: "Squish"), Effect(id: 8, effect: "Crush"), Effect(id: 9, effect: "Cake-ify"), Effect(id: 10, effect: "Ta-da"), Effect(id: 11, effect: "Deflate"), Effect(id: 12, effect: "Crumble"), Effect(id: 13, effect: "Dissolve")]
        escaping(arr)
        
    }
    
    
    func createVideo(data: Data, idEffect: String, escaping: @escaping (String) -> Void) {
        let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
        
        let headers: HTTPHeaders = [.authorization(bearerToken: token)]
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(idEffect.utf8), withName: "templateId")
            multipartFormData.append(data, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
            multipartFormData.append(Data(userID.utf8), withName: "userId")
        }, to: "https://vewapnew.online/api/generate", headers: headers)
        .responseData { response in
            debugPrint(response)
            switch response.result {
            case .success(let data):
                do {
                    let effects = try JSONDecoder().decode(Generate.self, from: data)
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
        
        let header: HTTPHeaders = [(.authorization(bearerToken: token))]
        let param: Parameters = ["generationId": itemId]

        
        
        AF.request("https://vewapnew.online/api/generationStatus", method: .get, parameters: param, headers: header).responseData { response in
            debugPrint(response, "statusGettttt")
            switch response.result {
            case .success(let data):
                do {
                    let item = try JSONDecoder().decode(Status.self, from: data)
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

    
}

