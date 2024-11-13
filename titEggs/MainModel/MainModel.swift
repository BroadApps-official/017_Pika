//
//  MainModel.swift
//  titEggs
//
//  Created by Владимир Кацап on 06.11.2024.
//

import Foundation
import Combine
import Network

class MainModel {
    
    private let netWorking = NetWorking()
    
    lazy var arr: [Video] = loadVideoArrFromFile()  ?? []
    
    var effectsArr: [Effect] = []
    
    var workItems: [DispatchWorkItem] = []
    
    var publisherVideo = PassthroughSubject<Any, Never>()
    
    var errorPublisher = PassthroughSubject<(Bool, String), Never>()
    var videoDownloadedPublisher = PassthroughSubject<String, Never>()
    
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
    

    func checkConnect(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                completion(true)
            } else {
                completion(false)
            }
            monitor.cancel() // Остановим мониторинг, чтобы избежать утечек памяти
        }
        
        monitor.start(queue: queue)
    }

    
    func createVideo( escaping: @escaping(Bool) -> Void) {
        
        checkConnect { isConnected in
            if isConnected == true {
                
                DispatchQueue.main.async {
                    self.checkStatus()
                    self.publisherVideo.send(1)
                    escaping(true)
                }

            } else {
                escaping(false)
            }
        }
        
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
        print(itemId, "fgvxbnv")
        self.netWorking.getStatus(itemId: itemId) { status, resultUrl in
            print(status, itemId, "fsfdsvfsdvccsv")
            if status != "fail" && resultUrl != "fail" && resultUrl != "" {
                
                print("Получены данные для индекса \(index): статус - \(status), URL - \(resultUrl), idGen - \(self.arr[index].generationID)")
                self.arr[index].resultURL = resultUrl
                self.arr[index].status = status
                self.saveArr()
                
                self.netWorking.downloadVideo(from: self.arr[index].resultURL!) { data, error in
                    if error == nil {
                        self.arr[index].video = data
                        self.saveArr()
                        self.publisherVideo.send(1)
                        self.checkStatus()
                        self.videoDownloadedPublisher.send("\(self.arr[index].id)")
                        workItem?.cancel()
                    }
                }
            } else if status == "error" || status == "fail" {
                workItem?.cancel()
                self.arr[index].status = "error"
                self.saveArr()
                self.errorPublisher.send((false,  "\(self.arr[index].id)"))
                self.publisherVideo.send(1)
                print("error load is - " , "\(self.arr[index].id)")
            } else if !(workItem?.isCancelled ?? true) {
                print("Повторный запрос для индекса \(index) через 5 секунд...")
                self.publisherVideo.send(1)
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
            if (element.resultURL == nil || element.video == nil) && element.status != "error" {
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
                            
                            print(self.arr[index], "create genID")
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


