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
    let previewVideoName: String
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let videoContainerView = UIView() // Контейнер для видео
    private var playPauseButton: UIButton!
    private var hideButtonTimer: DispatchWorkItem?
    private lazy var taps = 0
    
    private lazy var cancellable = [AnyCancellable]()
    var publisher: PassthroughSubject<Bool, Never>
    
    init(model: MainModel, index: Int, purchaseManager: PurchaseManager, previewVideoName: String, publisher: PassthroughSubject<Bool, Never>) {
        self.model = model
        self.index = index
        self.purchaseManager = purchaseManager
        self.previewVideoName = previewVideoName
        self.publisher = publisher
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavController()
        view.backgroundColor = .bgPrimary
        setupUI()
        subscribe()
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
        
        
        self.setupPlayer()
        self.view.layoutIfNeeded()
    }
    
    private func setupPlayer() {

        guard let videoURL = Bundle.main.url(forResource: previewVideoName, withExtension: "mp4") else {
            print("Video file not found")
            return
        }
        
        // Инициализируем AVPlayer с URL видеофайла
        player = AVPlayer(url: videoURL)
        
        // Настраиваем слой для отображения видео
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.cornerRadius = 20
        
        videoContainerView.layoutIfNeeded()
        playerLayer?.frame = videoContainerView.bounds
        videoContainerView.layer.addSublayer(playerLayer!)
        playerLayer?.setNeedsDisplay()
        
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
        playPauseButton.alpha = 1
        playPauseTapped()
    }

    
    @objc private func playPauseTapped() {
        print(123)
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

}
