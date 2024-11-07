//
//  MainModel.swift
//  titEggs
//
//  Created by Владимир Кацап on 06.11.2024.
//

import Foundation
import Combine

class MainModel {
    
    private let netWorking = NetWorking()
    
    lazy var arr: [Video] = loadVideoArrFromFile()  ?? []
    
    var effectsArr: [Effect] = []
    
    private var workItems: [DispatchWorkItem] = []
    
    var publisherVideo = PassthroughSubject<Any, Never>()
    var videoCreatedPublisher = PassthroughSubject<Int, Never>()
    
    init() {
        checkStatus()
        print(arr)
    }
    
    
    func loadEffectArr(escaping: @escaping() -> Void) {
        netWorking.loadEffectsArr { effect in
            self.effectsArr = effect
            escaping()
        }
    }
    
    
    
    func createVideo(image:Data, idEffect: Int, escaping: @escaping(Bool) -> Void) {
        var nameEffect = "Effect"
        
        for i in effectsArr {
            if i.id == idEffect {
                nameEffect = i.effect
            }
        }
        
        let video = Video(image: image, effectID: idEffect, video: nil, generationID: nil, resultURL: nil, dataGenerate: self.getTodayFormattedData(), effectName: nameEffect)
        
        self.arr.append(video)
        self.saveArr()
        checkStatus()
        publisherVideo.send(1)
        
    }
    
    
    func getTodayFormattedData() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let today = Date()
        return dateFormatter.string(from: today)
    }

    
    func saveArr() {
        do {
            let data = try JSONEncoder().encode(arr)
            try saveVideoArrToFile(data: data)
        } catch {
            print("Failed to encode or save athleteArr: \(error)")
        }
    }
    
    
    func checkStatusForIndex(index: Int, workItem: DispatchWorkItem?) {
        
        let itemId = self.arr[index].generationID ?? "" // Используем id элемента для запроса
        print(itemId)
        self.netWorking.getStatus(itemId: itemId) { status, resultUrl in
            if status != "fail" && resultUrl != "fail" {
                print("Получены данные для индекса \(index): статус - \(status), URL - \(resultUrl)")
                self.arr[index].resultURL = resultUrl
                self.netWorking.downloadVideo(from: self.arr[index].resultURL ?? "") { data, error in
                    if error == nil {
                        self.arr[index].video = data
                        self.saveArr()
                        self.publisherVideo.send(1)
                        workItem?.cancel()
                    }
                }
            } else if !(workItem?.isCancelled ?? true) {
                print("Повторный запрос для индекса \(index) через 5 секунд...")
                DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: workItem!)
            }
        }
    }
    
    func checkStatus() {
        workItems.forEach { $0.cancel() }
        workItems.removeAll()
        
        // Поиск индексов для проверки
        var indices: [Int] = []
        for (index, element) in arr.enumerated() {
            if element.resultURL == nil || element.video == nil {
                indices.append(index)
            }
        }
        print(indices, arr)

        for index in indices {
            var workItem: DispatchWorkItem?
            workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                // Дополнительная проверка на существование индекса
                guard index < self.arr.count else {
                    print("Index \(index) out of range")
                    return
                }
                
                if self.arr[index].generationID == nil || self.arr[index].generationID == "error" {
                    
                    let idEffect = "\(self.arr[index].effectID)"
                    self.netWorking.createVideo(data: self.arr[index].image, idEffect: idEffect) { [weak self] idVideo in
                        guard let self = self else { return }
                        
                        DispatchQueue.main.async {
                            // Еще раз проверяем наличие индекса перед доступом
                            guard index < self.arr.count else {
                                print("Index \(index) out of range in completion")
                                return
                            }
                            
                            self.arr[index].generationID = idVideo // Присваиваем полученный generationID
                            self.saveArr()
                            self.checkStatusForIndex(index: index, workItem: workItem)
                        }
                    }
                } else {
                    // Если generationID уже есть, сразу вызываем проверку статуса
                    DispatchQueue.main.async {
                        self.checkStatusForIndex(index: index, workItem: workItem)
                    }
                }
            }

            if let workItem = workItem {
                workItems.append(workItem)
                DispatchQueue.global().async(execute: workItem)
            }
        }
    }

    
    
    private func loadVideoArrFromFile() -> [Video]? {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to get document directory")
            return nil
        }
        let filePath = documentDirectory.appendingPathComponent("video.plist")
        do {
            let data = try Data(contentsOf: filePath)
            let athleteArr = try JSONDecoder().decode([Video].self, from: data)
            return athleteArr
        } catch {
            print("Failed to load or decode athleteArr: \(error)")
            return nil
        }
    }
    
    
    private func saveVideoArrToFile(data: Data) throws {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = documentDirectory.appendingPathComponent("video.plist")
            try data.write(to: filePath)
        } else {
            throw NSError(domain: "SaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to get document directory"])
        }
    }
}


