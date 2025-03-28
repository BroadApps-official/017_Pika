//
//  DataModel.swift
//  titEggs
//
//  Created by Владимир Кацап on 07.11.2024.
//

import Foundation

struct DataEffect: Codable {
    let error: Bool
    let messages: [String]
    let data: [Category]
}

// Структура для категорий
struct Category: Codable {
    let categoryId: Int
    let categoryTitleRu: String
    let categoryTitleEn: String
    let templates: [Effect]
}

struct Effect: Codable {
    let id: Int
    let title: String
    let categoryId: Int
    let categoryTitleRu: String
    let categoryTitleEn: String
    let ai: String
    var effect: String
    let preview: String?
    let previewSmall: String?
}



//video
struct Video: Codable, Identifiable {
    let id: UUID
    var image: Data
    var effectID: Int
    var effectName: String
    var video: Data?
    var generationID: String?
    var resultURL: String?
    var dataGenerate: String
    var status: String?
    var secondImage: Data? // Делаем опциональным

    init(image: Data,
         effectID: Int,
         video: Data? = nil,
         generationID: String? = nil,
         resultURL: String? = nil,
         dataGenerate: String,
         effectName: String,
         status: String? = nil,
         secondImage: Data? = nil) { // Теперь опционально

        self.id = UUID()
        self.image = image
        self.effectID = effectID
        self.video = video
        self.generationID = generationID
        self.resultURL = resultURL
        self.dataGenerate = dataGenerate
        self.effectName = effectName
        self.status = status
        self.secondImage = secondImage // Теперь можно не передавать
    }
}


//work

struct Generate: Codable {
    let error: Bool
    let messages: [String]
    let data: DataGenerate
}

struct DataGenerate: Codable {
    let generationId: String
    let totalWeekGenerations: Int
    let maxGenerations: Int
}

//check stat

struct Status: Codable {
    let error: Bool
    let messages: [String]
    let data: StatusData
}

struct StatusData: Codable {
    let status: String?
    let error: String?
    let resultUrl: String?
    let progress: Int?
    let totalWeekGenerations: Int
    let maxGenerations: Int
}

//fetch user
struct UserInfoResponse: Decodable {
    let error: Bool
    let messages: [String]
    let data: UserData
}

struct UserData: Decodable {
    let availableGenerations: Int
}

struct ImgToVideoResponse: Codable {
    let error: Bool
    let messages: [String]
    let data: DataGenerate
}
