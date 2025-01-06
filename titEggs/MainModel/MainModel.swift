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
    
    lazy var arr: [Video] = loadVideoArrFromCache()  ?? []
    
    var effectsArr: [Effect] = []
    
    var workItems: [DispatchWorkItem] = []
    
    var publisherVideo = PassthroughSubject<Any, Never>()
    
    lazy var tokenPurchaseManager = TokenManager()
    
    var errorPublisher = PassthroughSubject<(Bool, String), Never>()
    var videoDownloadedPublisher = PassthroughSubject<String, Never>()
    
    private var timer: Timer?
    
    init() {
        startFetchingUserRepeat()
        checkStatus()
        fetchUserInfo { _ in
            print(1)
        }
    }
    
    
    func loadEffectArr(escaping: @escaping() -> Void) {
        netWorking.loadEffectsArr { effect in
            var arr: [Effect] = []
            
            for i in effect {
                if i.preview != nil && i.previewSmall != nil {
                    var item = i
                    item.effect = item.title ?? i.effect
                    arr.append(item)
                }
            }
            
            self.effectsArr = arr
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
            monitor.cancel()
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
    
    
//    func loadPreviewVideo(idEffect: Int, escaping:  @escaping(Data, Bool) -> Void) {
//        netWorking.loadPreviewVideo(idEffect: idEffect) { data, isError in
//            escaping(data, isError)
//        }
//    }

    
    func saveArr() {
        do {
            let data = try JSONEncoder().encode(arr)
            try saveVideoArrToFile(data: data)
            print("Массив видео успешно сохранен в кэш.")
        } catch {
            print("Ошибка при кодировании или сохранении массива видео: \(error)")
        }
    }
    
    
    func checkStatusForIndex(index: Int, workItem: DispatchWorkItem?) {
        
        guard index < self.arr.count else {
            print("Index \(index) out of range in completion")
            return
        }
        
        let itemId = self.arr[index].generationID ?? "" // Используем id элемента для запроса
        print(itemId, "fgvxbnv")
        self.netWorking.getStatus(itemId: itemId) { status, resultUrl in
            print(status, itemId, "fsfdsvfsdvccsv")
            if status != "fail" && resultUrl != "fail" && resultUrl != "" && status != "error" {
                
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
                print("Повторный запрос для индекса \(index) через 20 секунд...")
                self.publisherVideo.send(1)
                DispatchQueue.global().asyncAfter(deadline: .now() + 20, execute: workItem!)
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
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                self.checkStatusForIndex(index: index, workItem: workItem)
                            }
                        }
                    }
                } else {
                    // Если generationID уже есть, сразу вызываем проверку статуса
                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
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

    
    
    private func loadVideoArrFromCache() -> [Video]? {
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Unable to get cache directory")
            return nil
        }
        let filePath = cacheDirectory.appendingPathComponent("videoArrayCache.plist")
        
        do {
            let data = try Data(contentsOf: filePath)
            let videoArr = try JSONDecoder().decode([Video].self, from: data)
            print("Видео успешно загружены из кэша.")
            return videoArr
        } catch {
            print("Ошибка при загрузке или декодировании массива видео: \(error)")
            return nil
        }
    }

    
    
    private func saveVideoArrToFile(data: Data) throws {
        let fileManager = FileManager.default
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let filePath = cacheDirectory.appendingPathComponent("videoArrayCache.plist")
            try data.write(to: filePath)
        } else {
            throw NSError(domain: "SaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to get cache directory"])
        }
    }
    
    func fetchUserInfo(escaping: @escaping(Bool) -> Void) {
        netWorking.fetchUserInfo { isError, weekgen  in
            UserDefaults.standard.setValue("\(weekgen * 10)", forKey: "amountTokens")
            if weekgen == 0 {
                escaping(false)
            } else {
                escaping(true)
            }
        }
    }
    
    func startFetchingUserRepeat() {
        // Останавливаем предыдущий таймер, если он был запущен
        stopFetchingUserRepeat()
        
        // Создаем новый таймер
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchUserRepeat()
        }
        
        // Добавляем таймер в текущий RunLoop
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func stopFetchingUserRepeat() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchUserRepeat() {
        // Вызов метода
        netWorking.fetchUserInfo { isOK, tokens in
            UserDefaults.standard.setValue("\(tokens * 10)", forKey: "amountTokens")
            print(tokens * 10, "TOFOMVVVV")
        }
    }
    
}


