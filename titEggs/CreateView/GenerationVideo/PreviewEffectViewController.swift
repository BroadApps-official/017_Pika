//
//  PreviewEffectViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 13.11.2024.
//

import UIKit
import AVFoundation
import Combine
import GSPlayer

class PreviewEffectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    let model: MainModel
    let index: Int
    let purchaseManager: PurchaseManager

    
    private let playerView = VideoPlayerView()
    private var playPauseButton: UIButton!
    private var hideButtonTimer: DispatchWorkItem?
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
        playerView.pause(reason: .userInteraction)
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
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        playerView.addGestureRecognizer(tapGesture)
        view.addSubview(playerView)
        playerView.layer.cornerRadius = 20
        playerView.clipsToBounds = true
        playerView.replay(resetCount: true)
        playerView.playerLayer.videoGravity = .resizeAspectFill
        playerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(nextButton.snp.top).inset(-30)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(10)
        }
        
        // Настраиваем кнопку play/pause
        playPauseButton = UIButton(type: .custom)
        playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        playPauseButton.backgroundColor = .clear
        
        playPauseButton.alpha = 0
        activityIndicator.startAnimating()
        
        playerView.stateDidChanged = { state in
            switch state {
            case .none:
                print("none")
            case .error(let error):
                print("error - \(error.localizedDescription)")
            case .loading:
                print("loading")
            case .paused(let playing, let buffering):
                print("paused - progress \(Int(playing * 100))% buffering \(Int(buffering * 100))%")
            case .playing:
                self.activityIndicator.stopAnimating()
            }
        }
        
        
        self.setupPlayer()
        self.view.layoutIfNeeded()
    }
    
   
    
    private func setupPlayer() {
        playerView.play(for: URL(string: model.effectsArr[index].preview!)!)
       
        view.addSubview(playPauseButton)
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
        }
        alert.addAction(repeatButton)
        self.present(alert, animated: true)
    }

    
    @objc private func playPauseTapped() {
        taps += 1
        if playerView.state == .playing {
            playerView.pause(reason: .userInteraction)
            playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        } else {
            playerView.resume()
            playPauseButton.setBackgroundImage(.bigPause, for: .normal)
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
        //playPauseButton.isSelected = player?.rate != 0
        
        hideButtonTimer?.cancel()
        
        hideButtonTimer = DispatchWorkItem { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.playPauseButton.alpha = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: hideButtonTimer!)
    }
    
    
    @objc private func nextTapped() {

        if purchaseManager.hasUnlockedPro == true {
            if dynamicAppHud?.segment == "v2" {
                model.fetchUserInfo { isError in
                   
                    if isError == false {
                        self.openAmountAlert()
                    } else {
                        self.cellTapped(index: self.index)
                    }
                }
               
            } else {
                self.cellTapped(index: index)
            }
        } else {
            let vc = CreateElements.openPaywall(manager: purchaseManager)
            self.present(vc, animated: true)
            playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
            playerView.pause(reason: .userInteraction)
        }
    }
    
    private func openAmountAlert() {
        let alert = UIAlertController(title: "Attention", message: "You ran out of generations this week, they are updated every week on Monday", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Close", style: .cancel)
        alert.addAction(okAction)
        
        let buyAction = UIAlertAction(title: "Show more", style: .default) { _ in
            self.openPaywallToken()
        }
        alert.addAction(buyAction)
        self.present(alert, animated: true)
    }
    
    func openPaywallToken() {
        let paywallViewController = TokenPaywallViewController(model: model)
        paywallViewController.modalPresentationStyle = .fullScreen
        paywallViewController.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            paywallViewController.isModalInPresentation = true
        }
        self.present(paywallViewController, animated: true)
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
        playerView.pause(reason: .userInteraction)
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
        playerView.pause(reason: .userInteraction)
        playPauseButton.setBackgroundImage(.bigPlay, for: .normal)
        
    }
    
    


}
