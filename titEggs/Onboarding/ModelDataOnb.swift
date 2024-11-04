//
//  ModelDataOnb.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import Foundation


struct OnbData: Codable {
    let image: String
    let topText: String
    let botText: String
    
    init(image: String, topText: String, botText: String) {
        self.image = image
        self.topText = topText
        self.botText = botText
    }
}
