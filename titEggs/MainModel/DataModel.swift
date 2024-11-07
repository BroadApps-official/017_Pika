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
    let data: [Effect]
}

struct Effect: Codable {
    var id: Int
    var effect: String
}


//video
struct Video: Codable {
    var image: Data
    var effectID: Int
    var effectName: String
    var video: Data?
    var generationID: String?
    var resultURL: String?
    var dataGenerate: String
    
    init(image: Data, effectID: Int, video: Data?, generationID: String?, resultURL: String?, dataGenerate: String, effectName: String) {
        self.image = image
        self.effectID = effectID
        self.video = video
        self.generationID = generationID
        self.resultURL = resultURL
        self.dataGenerate = dataGenerate
        self.effectName = effectName
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
}

//check stat

struct Status: Codable {
    let error: Bool
    let messages: [String]
    let data: StatusData
}

struct StatusData: Codable {
    let status: String
    let resultUrl: String
    let progress: Int?
}
