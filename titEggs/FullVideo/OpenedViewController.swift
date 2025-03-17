//
//  OpenedViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 07.11.2024.
//

import UIKit
import AVFoundation
import StoreKit
import Photos
import MobileCoreServices
import Combine

class OpenedViewController: UIViewController {

    let model: MainModel
    let index: Int


    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let videoContainerView = UIView() 
    private var playPauseButton: UIButton!
    private var hideButtonTimer: DispatchWorkItem?

    private var tempURL: URL?

    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTouchFeedback()
        button.setTitle("Share", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .appFont(.BodyRegular)
        button.layer.cornerRadius = 10
        button.backgroundColor = .primary
        let image = UIImage.shareBut.withRenderingMode(.alwaysTemplate).resize(targetSize: CGSize(width: 32, height: 32))
        button.setImage(image, for: .normal)
        button.tintColor = .black
        return button
    }()

    private lazy var taps = 0
  private var cancellables = Set<AnyCancellable>()

    init(model: MainModel, index: Int) {
        self.model = model
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavController()
    }

  override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .bgPrimary
      hidesBottomBarWhenPushed = true

      // Подписка на обновление видео
      model.publisherVideo
          .receive(on: DispatchQueue.main)
          .sink { [weak self] _ in
              guard let self = self else { return }
              print("⚡ Видео обновилось, перезапускаем setupUI()!")
              self.setupUI()
          }
          .store(in: &cancellables)

      setupUI()
  }

    private func setupNavController() {
        self.title = "Result"
        self.navigationItem.setHidesBackButton(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.appFont(.HeadlineRegular)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.appFont(.LargeTitleEmphasized)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        let backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
        navigationController?.navigationBar.tintColor = .primary

        let detailButton = UIButton(type: .system)
        detailButton.setBackgroundImage(.detailVideo, for: .normal)
        let barButtonItem = UIBarButtonItem(customView: detailButton)
        navigationItem.rightBarButtonItem = barButtonItem
        detailButton.snp.makeConstraints { make in
            make.width.equalTo(23)
            make.height.equalTo(22)
        }
        detailButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

    }

    private func setupUI() {
      print("🚀 setupUI вызван!")

        guard index >= 0, index < model.arr.count else {
            print("❌ Индекс вне диапазона! index = \(index), всего элементов: \(model.arr.count)")
            return
        }

        guard let videoData = model.arr[index].video else {
            print("❌ Видео отсутствует в model.arr[index]")
            return
        }

        print("✅ Данные найдены, создаём UI!")

      
        view.addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        shareButton.addTarget(self, action: #selector(shareVideo), for: .touchUpInside)

        // Добавляем контейнер для видео
        view.addSubview(videoContainerView)
        videoContainerView.layer.cornerRadius = 20
        videoContainerView.clipsToBounds = true
        videoContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(self.videoContainerView.snp.width).multipliedBy(1.35)
            make.centerY.equalToSuperview()
        }
        videoContainerView.backgroundColor = .clear

        // Настраиваем кнопку play/pause
        playPauseButton = UIButton(type: .custom)
        playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        playPauseButton.backgroundColor = .clear

        playPauseButton.alpha = 0   //self.setupPlayer(with: videoData)

        // Добавляем тап жест для видео
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
         guard index >= 0, index < model.arr.count else {
          print("Ошибка: индекс вне диапазона! index = \(index), размер массива = \(model.arr.count)")
          return
      }
        guard let videoData = model.arr[index].video else { return }

        videoContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(shareButton.snp.top).inset(-30)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(10)
        }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          guard let videoData = self.model.arr[self.index].video else {
              print("❌ Видео не найдено после задержки!")
              return
          }
          print("🎥 Новое видео загружено, запускаем setupPlayer()")
          self.setupPlayer(with: videoData)
      }
        self.view.layoutIfNeeded()
    }

    private func setupPlayer(with videoData: Data) {

        let tempDirectory = FileManager.default.temporaryDirectory
        removeOldTempVideos()

         let uniqueFileName = "tempVideo_\(UUID().uuidString).mp4"
          tempURL = tempDirectory.appendingPathComponent(uniqueFileName)

        // Пытаемся сохранить data как временный файл
        guard let tempFileURL = tempURL else { return }

        do {
            try videoData.write(to: tempFileURL)
        } catch {
            return
        }

        // Инициализируем AVPlayer с URL видеофайла
        player = AVPlayer(url: tempFileURL)

        // Настраиваем слой для отображения видео
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.cornerRadius = 20
        player?.actionAtItemEnd = .none

        videoContainerView.layoutIfNeeded()
        playerLayer?.frame = videoContainerView.bounds

      videoContainerView.layer.sublayers?.forEach { layer in
          if layer is AVPlayerLayer {
              layer.removeFromSuperlayer()
          }
      }

        if let playerLayer = playerLayer {
            videoContainerView.layer.addSublayer(playerLayer)
        }

        // Следим за окончанием видео
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        videoContainerView.addSubview(playPauseButton)
        playPauseButton.snp.makeConstraints { make in
            make.height.width.equalTo(76)
            make.center.equalToSuperview()
        }
        playPauseButton.alpha = 0
        playPauseTapped()
    }

  private func removeOldTempVideos() {
      let tempDirectory = FileManager.default.temporaryDirectory
      let fileManager = FileManager.default

      do {
          let files = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
          let videoFiles = files.filter { $0.lastPathComponent.hasPrefix("tempVideo_") && $0.pathExtension == "mp4" }

          if videoFiles.count > 1 {
              for file in videoFiles {
                  if file != tempURL {
                      try fileManager.removeItem(at: file)
                      print("🗑 Удалён старый файл: \(file.path)")
                  }
              }
          }
      } catch {
          print("❌ Ошибка очистки временных файлов: \(error.localizedDescription)")
      }
  }

    @objc private func shareVideo() {
        guard let tempURL = tempURL else {
            print("Нет временного файла для видео.")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        activityViewController.excludedActivityTypes = [
            .addToReadingList,
        ]

        // Настройка для iPad
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // Центр экрана
            popoverController.permittedArrowDirections = [] // Убираем стрелку поповера
        }

        self.present(activityViewController, animated: true, completion: {
            if UserDefaults.standard.object(forKey: "rewiew") == nil {
                var share: Int = UserDefaults.standard.integer(forKey: "share")
                share += 1
                UserDefaults.standard.setValue(share, forKey: "share")
                if share == 1 || share == 5 {
                    self.rateApp()
                }
            }
        })
    }


    private func rateApp() {
        if #available(iOS 14, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                DispatchQueue.main.async {
                    AppStore.requestReview(in: scene)
                }
            }
        } else {
            let appID = "ID"
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }


    private func presentShareSheet(with videoURL: URL) {

        let activityViewController = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true, completion: nil)
        }
    }


    @objc private func videoTapped() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playPauseButton.alpha = 1
        }
        playPauseButton.isSelected = player?.rate != 0

        hideButtonTimer?.cancel()

        hideButtonTimer = DispatchWorkItem { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.playPauseButton.alpha = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: hideButtonTimer!)
    }


    @objc private func playPauseTapped() {
        taps += 1
        if player?.rate == 0 {
            player?.play()
            playPauseButton.setBackgroundImage(.bigPause, for: .normal)
        } else {
            player?.pause()
            playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        }

        hideButtonTimer?.cancel()

        // Запускаем новый таймер для скрытия кнопки через 2 секунды
        hideButtonTimer = DispatchWorkItem { [weak self] in
            self?.playPauseButton.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: hideButtonTimer!)

    }

    @objc private func videoDidFinish() {
        player?.seek(to: .zero)
        player?.play()
    }



    func removeTempFile() {
        guard let tempURL = tempURL else { return }
        try? FileManager.default.removeItem(at: tempURL)
        self.tempURL = nil
    }

    @objc private func buttonTapped(_ sender: UIButton) {

        let imageSave = getImageForCurrentTheme(image: UIImage.saveGallery)
        let firstAction = UIAction(title: "Save to gallery", image: imageSave.resize(targetSize: CGSize(width: 20, height: 20))) { _ in
            self.saveInGallery()
        }

        let imageSaveFiled =  getImageForCurrentTheme(image: UIImage.saveFiles)
        let secondAction = UIAction(title: "Save to files", image: imageSaveFiled.resize(targetSize: CGSize(width: 20, height: 44))) { _ in
            self.saveToFiles()
        }

        let redTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.red
        ]
        let imageTrash = UIImage.delete
        let deleteTitle = NSAttributedString(string: "Delete", attributes: redTextAttributes)

        let threeAction = UIAction(title: deleteTitle.string, image: imageTrash.resize(targetSize: CGSize(width: 20, height: 44))) { _ in
            self.delete()
        }

        let menu = UIMenu(title: "", children: [firstAction, secondAction, threeAction])


        if #available(iOS 14.0, *) {
            sender.menu = menu
            sender.showsMenuAsPrimaryAction = true
        }
    }

    //DataFlow

    private func saveToFiles() {
        // Проверяем, что tempURL не равен nil
        guard let tempURL = tempURL else {
            showErrorAlertFiles()
            return
        }

        // Проверяем, что файл существует
        if !FileManager.default.fileExists(atPath: tempURL.path) {
            print("Файл не найден по пути: \(tempURL.path)")
            showErrorAlertFiles()
            return
        }

        // Создаем Document Picker для экспорта файла
        let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }



    private func showErrorAlertFiles() {
        let alert = UIAlertController(title: "Error, video not saved to files", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)

        let retryAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.saveToFiles()
        }
        alert.addAction(retryAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func showSuccessAlertFiles() {
        let alert = UIAlertController(title: "Video saved to files", message: "", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)

        present(alert, animated: true, completion: nil)
    }



    private func saveInGallery() {
        guard let videoURL = tempURL else {
            self.showErrorAlert()
            return
        }

        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Сохраняем видео в галерею
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                    creationRequest?.creationDate = Date()
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.showSuccessAlert()
                        } else {
                            self.showErrorAlert()
                        }
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.showErrorAlert()
                }
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        self.saveInGallery()
                    } else {
                        self.showErrorAlert()
                    }
                }
            case .limited:
                self.showErrorAlert()
            @unknown default:
                self.showErrorAlert()
            }
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(title: "Error, video not saved to gallery", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)

        let retryAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.saveInGallery()
        }
        alert.addAction(retryAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Video saved to gallery", message: "", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)

        present(alert, animated: true, completion: nil)
    }


    private func delete() {
        let alertController = UIAlertController(title: "Delete this video?", message: "It will disappear from the history in the My Videos tab. You will not be able to restore it after deletion.", preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancel)

        let ok = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
            model.arr.remove(at: index)
            model.saveArr()
            model.publisherVideo.send(1)
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(ok)

        self.present(alertController, animated: true)
    }

    //

    func getImageForCurrentTheme(image: UIImage) -> UIImage {
        let currentMode = traitCollection.userInterfaceStyle
        let image = image.withRenderingMode(.alwaysTemplate)
        switch currentMode {
        case .dark:
            return image.withTintColor(.white)  // Белый цвет для темной темы
        case .light, .unspecified:
            return image.withTintColor(.black)  // Черный цвет для светлой темы
        @unknown default:
            return image.withTintColor(.black)  // Черный цвет по умолчанию
        }
    }



    deinit {
        removeTempFile()
        hideButtonTimer?.cancel()
    }

}


extension OpenedViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("Видео сохранено в: \(urls.first?.path ?? "Unknown")")
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Пользователь отменил выбор")
    }
}
