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

    lazy var arr: [Video] = loadVideoArrFromCache() ?? []
    var effectsArr: [Effect] = []

    var workItems: [DispatchWorkItem] = []
    private let workItemsQueue = DispatchQueue(label: "workItemsQueue", attributes: .concurrent)

    var publisherVideo = PassthroughSubject<Any, Never>()
    var errorPublisher = PassthroughSubject<(Bool, String), Never>()
    var videoDownloadedPublisher = PassthroughSubject<String, Never>()
    lazy var tokenPurchaseManager = TokenManager()

    private var timer: Timer?

    init() {
        startFetchingUserRepeat()
        if !arr.isEmpty {
            checkStatus()
        }
        fetchUserInfo { _ in
            print(1)
        }
    }

    func loadEffectArr(escaping: @escaping () -> Void) {
        netWorking.loadEffectsArr { categories in
            var arr: [Effect] = []
            for category in categories {
                for var effect in category.templates {
                    if let _ = effect.preview, let _ = effect.previewSmall {
                        effect.effect = effect.title
                        arr.append(effect)
                    }
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
            completion(path.status == .satisfied)
            monitor.cancel()
        }
        monitor.start(queue: queue)
    }

    func createVideo(escaping: @escaping (Bool) -> Void) {
        checkConnect { isConnected in
            if isConnected {
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
            print("Массив видео успешно сохранен в кэш.")
        } catch {
            print("Ошибка при кодировании или сохранении массива видео: \(error)")
        }
    }

    func checkStatusForIndex(index: Int) {
        guard index < self.arr.count else {
            print("Index \(index) out of range in completion")
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard index < self.arr.count else { return }
            
            let itemId = self.arr[index].generationID ?? ""
            let videoId = "\(self.arr[index].id)"
            
            // Добавляем проверку на пустой ID
            guard !itemId.isEmpty else {
                print("Empty generation ID for index \(index)")
                return
            }
            
            self.netWorking.getStatus(itemId: itemId) { [weak self] status, resultUrl in
                guard let self = self else { return }
                
                // Выполняем на главном потоке
                DispatchQueue.main.async {
                    guard index < self.arr.count else { return }
                    
                    print(status, itemId, "fsfdsvfsdvccsv")
                    if status != "fail" && resultUrl != "fail" && resultUrl != "" && status != "error" {
                        print("Получены данные для индекса \(index): статус - \(status), URL - \(resultUrl), idGen - \(self.arr[index].generationID)")
                        self.arr[index].resultURL = resultUrl
                        self.arr[index].status = status
                        self.saveArr()

                        // Загружаем видео только если оно еще не загружено
                        if self.arr[index].video == nil {
                            self.netWorking.downloadVideo(from: resultUrl) { data, error in
                                if error == nil, let data = data {
                                    DispatchQueue.main.async {
                                        self.arr[index].video = data
                                        self.saveArr()
                                        self.publisherVideo.send(1)
                                        self.videoDownloadedPublisher.send(videoId)
                                    }
                                }
                            }
                        }
                    } else if status == "error" || status == "fail" {
                        print("error load is -", videoId)
                        self.arr[index].status = "error"
                        self.saveArr()
                        self.errorPublisher.send((false, videoId))
                        self.publisherVideo.send(1)
                    } else {
                        print("Повторный запрос для индекса \(index) через 20 секунд...")
                        DispatchQueue.global().asyncAfter(deadline: .now() + 20) {
                            self.checkStatusForIndex(index: index)
                        }
                    }
                }
            }
        }
        
        workItemsQueue.async(flags: .barrier) {
            self.workItems.append(workItem)
        }

        DispatchQueue.global().async(execute: workItem)
    }

    func checkStatus() {
        workItems.forEach {
            if !$0.isCancelled {
                $0.cancel()
            }
        }

        workItems.removeAll()

        if arr.isEmpty {
            print("📌 Массив `arr` пуст, проверка статусов не выполняется.")
            return
        }

        var indices: [Int] = []
        for (index, element) in arr.enumerated() {
            if (element.resultURL == nil || element.video == nil) && element.status != "error" {
                indices.append(index)
            }
        }
        print("📌 Индексы для проверки:", indices)

        for index in indices {
            guard index < arr.count else { continue }

            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else {
                    print("❌ self освобождён, работа отменена")
                    return
                }

                guard index < self.arr.count else {
                    print("❌ Ошибка: Index \(index) out of range")
                    return
                }

                let effectID = "\(self.arr[index].effectID)"
                let effectName = self.arr[index].effectName
                let isHugAndKiss = effectName.contains("Hug") || effectName.contains("Kiss")

                var imagesToSend: [Data] = []
                if isHugAndKiss {
                    if let secondImage = self.arr[index].secondImage {
                        imagesToSend = [self.arr[index].image, secondImage]
                    } else {
                        imagesToSend = [self.arr[index].image]
                    }
                } else {
                    imagesToSend = [self.arr[index].image]
                }

                if self.arr[index].generationID == nil || self.arr[index].generationID == "error" {
                    self.netWorking.createVideo(data: imagesToSend, idEffect: effectID, isHugAndKiss: isHugAndKiss) { [weak self] idVideo in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            guard index < self.arr.count else {
                                print("❌ Ошибка: Index \(index) out of range в completion")
                                return
                            }
                            print("✅ Успешно создано: \(self.arr[index]) → generationID: \(idVideo)")
                            self.arr[index].generationID = idVideo
                            self.saveArr()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                self.checkStatusForIndex(index: index)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                        self.checkStatusForIndex(index: index)
                    }
                }
            }

            workItemsQueue.async(flags: .barrier) {
                self.workItems.append(workItem)
            }

            DispatchQueue.global().async(execute: workItem)
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

    func fetchUserInfo(escaping: @escaping (Bool) -> Void) {
        netWorking.fetchUserInfo { isError, weekgen in
            UserDefaults.standard.setValue("\(weekgen * 10)", forKey: "amountTokens")
            escaping(weekgen != 0)
        }
    }

    func startFetchingUserRepeat() {
        stopFetchingUserRepeat()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchUserRepeat()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func stopFetchingUserRepeat() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchUserRepeat() {
        netWorking.fetchUserInfo { isOK, tokens in
            UserDefaults.standard.setValue("\(tokens * 10)", forKey: "amountTokens")
            print(tokens * 10, "TOFOMVVVV")
        }
    }

    // Метод для image2video – теперь используем тот же checkStatusForIndex
    func imageToVideo(imageData: Data, promptText: String, completion: @escaping (Bool, String?) -> Void) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_image.png")
        do {
            try imageData.write(to: tempURL)
        } catch {
            print("❌ Ошибка сохранения изображения во временный файл: \(error)")
            completion(false, nil)
            return
        }

        netWorking.uploadImageToVideo(imagePath: tempURL.path, promptText: promptText) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let generationId):
                print("✅ Видео сгенерировано! Generation ID: \(generationId)")
                let newVideo = Video(
                    image: imageData, effectID: 0,
                    video: nil,
                    generationID: generationId,
                    resultURL: nil,
                    dataGenerate: self.getTodayFormattedDate(),
                    effectName: "Promt",
                    status: nil,
                    secondImage: nil
                )
                self.arr.append(newVideo)
                self.saveArr()
                self.checkStatusForIndex(index: self.arr.count - 1)
                completion(true, "\(newVideo.id)")

            case .failure(let error):
                print("❌ Ошибка загрузки: \(error.localizedDescription)")
                completion(false, nil)
            }
        }
    }

    private func getTodayFormattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        return dateFormatter.string(from: Date())
    }

    var activeGenerationsCount: Int {
        return arr.filter { $0.status != "error" }.count
    }

    func hasReachedGenerationLimit() -> Bool {
        return activeGenerationsCount >= 2
    }

    func cache(data: Data, for url: URL) {
        let fileManager = FileManager.default
        if #available(iOS 11.0, *) {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                if let capacity = resourceValues.volumeAvailableCapacityForImportantUsage,
                   capacity < Int64(data.count) {
                    print("Недостаточно места на устройстве")
                    return
                }
            } catch {
                print("Ошибка при проверке свободного места: \(error)")
                return
            }
        } else {
            do {
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let systemAttributes = try fileManager.attributesOfFileSystem(forPath: paths[0])
                if let freeSize = systemAttributes[.systemFreeSize] as? NSNumber,
                   freeSize.int64Value < Int64(data.count) {
                    print("Недостаточно места на устройстве")
                    return
                }
            } catch {
                print("Ошибка при проверке свободного места: \(error)")
                return
            }
        }
    }
}
