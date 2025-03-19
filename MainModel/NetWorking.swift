func createVideo(data: Data, idEffect: String, escaping: @escaping (String) -> Void) {
    let token = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"
    
    let headers: HTTPHeaders = [(.authorization(bearerToken: token))]
    
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