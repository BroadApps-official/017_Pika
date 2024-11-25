//
//  PreviewEffectViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 13.11.2024.
//

import UIKit
import AVFoundation
import Combine

class PreviewEffectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    let model: MainModel
    let index: Int
    let purchaseManager: PurchaseManager

    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let videoContainerView = UIView() // Контейнер для видео
    private var playPauseButton: UIButton!
    private var hideButtonTimer: DispatchWorkItem?
    private var tempFileURL: URL?
    private lazy var taps = 0
    
    private lazy var cancellable = [AnyCancellable]()
    var publisher: PassthroughSubject<Bool, Never>
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .primary
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 16
        return view
    }()
    
    init(model: MainModel, index: Int, purchaseManager: PurchaseManager, publisher: PassthroughSubject<Bool, Never>) {
        self.model = model
        self.index = index
        self.purchaseManager = purchaseManager
        self.publisher = publisher
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        subscribe()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityIndicator.center = self.view.center
    }
    
   
    
    private func subscribe() {
        publisher
            .sink { result in
                print("ПАБЛИШЕР У ПРЕВЬЮ ВС ПОКАЗАН")
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &cancellable)
    }
    
    private func setupNavController() {
        self.title = model.effectsArr[index].effect
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
        
    }
    

    private func setupUI() {
        
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.height.width.equalTo(60)
            make.center.equalToSuperview()
        }
        

        let nextButton = UIButton(type: .system)
        nextButton.addTouchFeedback()
        nextButton.backgroundColor = .primary
        nextButton.setTitle("Continue", for: .normal)
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.titleLabel?.font = .appFont(.BodyRegular)
        nextButton.layer.cornerRadius = 10
        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
            make.height.equalTo(48)
        }
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        
        view.addSubview(videoContainerView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
        videoContainerView.layer.cornerRadius = 20
        videoContainerView.clipsToBounds = true
        videoContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(nextButton.snp.top).inset(-30)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(10)
        }
        videoContainerView.backgroundColor = .clear
        
        // Настраиваем кнопку play/pause
        playPauseButton = UIButton(type: .custom)
        playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        playPauseButton.backgroundColor = .clear
        
        playPauseButton.alpha = 0
        
        
        self.loadVideo()
        self.view.layoutIfNeeded()
    }
    
    private func loadVideo() {
        
        self.activityIndicator.startAnimating()
        
        model.loadPreviewVideo(idEffect: model.effectsArr[index].id) { dataVideo, isError in
            
            print(123000)
            
            if isError == true {
                self.openAlert()
            } else {
                self.setupPlayer(data: dataVideo)
            }
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func setupPlayer(data: Data) {
           // Устанавливаем путь к временному файлу
           let tempDirectory = FileManager.default.temporaryDirectory
           tempFileURL = tempDirectory.appendingPathComponent("tempVideo.mp4")
           
           // Пытаемся сохранить data как временный файл
           guard let tempFileURL = tempFileURL else { return }
           
           do {
               try data.write(to: tempFileURL)
           } catch {
               self.openAlert()
               return
           }
           
           // Инициализируем AVPlayer с URL видеофайла
           player = AVPlayer(url: tempFileURL)
           
           // Настраиваем слой для отображения видео
           playerLayer = AVPlayerLayer(player: player)
           playerLayer?.videoGravity = .resizeAspectFill
           playerLayer?.cornerRadius = 20
           
           videoContainerView.layoutIfNeeded()
           playerLayer?.frame = videoContainerView.bounds
           if let playerLayer = playerLayer {
               videoContainerView.layer.addSublayer(playerLayer)
           }
           
           // Запускаем воспроизведение видео
           player?.play()
           player?.actionAtItemEnd = .none
           
           // Добавляем наблюдатель для окончания видео
           NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
           
           // Настраиваем кнопку play/pause
           videoContainerView.addSubview(playPauseButton)
           playPauseButton.snp.makeConstraints { make in
               make.height.width.equalTo(76)
               make.center.equalToSuperview()
           }
           playPauseButton.alpha = 0
           playPauseTapped()
        playPauseTapped()
       }
    
    private func openAlert() {
        let alert = UIAlertController(title: "Video preview error", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(cancelButton)
        
        let repeatButton = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.activityIndicator.startAnimating()
            self.loadVideo()
        }
        alert.addAction(repeatButton)
        self.present(alert, animated: true)
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
    
    @objc private func videoDidFinish() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    @objc private func nextTapped() {
        
        if purchaseManager.hasUnlockedPro == true {
            self.cellTapped(index: index)
        } else {
            let vc = CreateElements.openPaywall(manager: purchaseManager)
            self.present(vc, animated: true)
            playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
            player?.pause()
        }
    }
    
    private func cellTapped(index: Int) {
        let alert = UIAlertController(title: "Select action", message: "Add a photo so we can do a cool effect with it", preferredStyle: .actionSheet)
        
        let dynamicTextColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle != .dark ? UIColor.bgChromeMaterialbar : UIColor.primary
        }
        
        let photoAction = UIAlertAction(title: "Take a photo", style: .default) { _ in
            self.openCamera()
        }
        photoAction.setValue(dynamicTextColor, forKey: "titleTextColor")
        alert.addAction(photoAction)
        
        let galleryAction = UIAlertAction(title: "Select from gallery", style: .default) { _ in
            self.enterPhotoInGallery()
        }
        galleryAction.setValue(dynamicTextColor, forKey: "titleTextColor")
        alert.addAction(galleryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(dynamicTextColor, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        
        // Установка popoverPresentationController для iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view // Основное представление или тот элемент, на котором была нажата ячейка
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // Центр экрана
            popoverController.permittedArrowDirections = [] // Убирает стрелку поповера
        }
        
        self.present(alert, animated: true)
    }
    
    private func selectedPhoto(image: Data) {
        openGenerateVC(image: image)
    }
    
    private func openGenerateVC(image: Data) {
        let generateVC = GenerateVideoViewController(model: model, image: image, index: index, publisher: publisher, video: nil)
        generateVC.modalPresentationStyle = .fullScreen
        generateVC.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            generateVC.isModalInPresentation = true
        }
        playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        player?.pause()
        self.present(generateVC, animated: true)
    }
    
    //MARK: -PHOTO
    
    private func enterPhotoInGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerController = UIImagePickerController()
            pickerController.sourceType = .photoLibrary
            pickerController.delegate = self
            pickerController.allowsEditing = false
            self.present(pickerController, animated: true, completion: nil)
        } else {
            print("Photo Library is not available.")
        }
    }
    
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let pickerController = UIImagePickerController()
            pickerController.sourceType = .camera
            pickerController.delegate = self
            pickerController.allowsEditing = false
            self.present(pickerController, animated: true, completion: nil)
        } else {
            print("Camera is not available.")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.selectedPhoto(image: imageData)
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        print(5555)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // Останавливаем воспроизведение и очищаем player
        player?.pause()
        playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        player = nil
        
        // Удаляем playerLayer из слоя videoContainerView
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        if let tempFileURL = tempFileURL {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
    }
    
    


}
