//
//  CreateViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import Combine
import AVFoundation
import AVKit

class CreateViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    private let rightButton = PaywallButton()
    
    var purchaseManager: PurchaseManager
    var model: MainModel
    
    private var selectedIndex = 0
    
    private lazy var cancellable = [AnyCancellable]()
    
    private lazy var activity: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .primary
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .bgPrimary
        collection.showsVerticalScrollIndicator = false
        layout.scrollDirection = .vertical
        collection.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: "VideoCollectionViewCell")

        collection.alpha = 0
        collection.delegate = self
        collection.dataSource = self
        layout.minimumInteritemSpacing = 10
        collection.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 15, right: 0)
        //layout.minimumLineSpacing = 15
        return collection
    }()
    
    
    init(purchaseManager: PurchaseManager, model: MainModel) {
        self.purchaseManager = purchaseManager
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavController()
        checkManager()
        
    }
    
    private func checkManager() {
        
        print(purchaseManager.hasUnlockedPro, "- есть или нет покупок")
        
        if purchaseManager.hasUnlockedPro {
            rightButton.alpha = 0
        } else {
            rightButton.alpha = 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadArr()
        subscribe()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupNavController()
    }
    
    private func loadArr() {
        view.addSubview(activity)
        activity.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.width.equalTo(64)
        }
        activity.startAnimating()
        collection.alpha = 0
        model.loadEffectArr {
            if self.model.effectsArr.count > 0 {
                UIView.animate(withDuration: 0.3) {
                    self.collection.alpha = 1
                    self.activity.removeFromSuperview()
                }
                self.collection.reloadData()
            }
        }
    }
    
    private func subscribe() {
        buyPublisher
            .sink { _ in
                self.checkManager()
            }
            .store(in: &cancellable)
   
    }
    
    private func setupNavController() {
        tabBarController?.title = "Create"
        tabBarController?.navigationController?.navigationBar.prefersLargeTitles = true
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
        tabBarController?.navigationController?.navigationBar.standardAppearance = appearance
        tabBarController?.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        if purchaseManager.hasUnlockedPro == false {
            rightButton.addTarget(self, action: #selector(paywallButtonTapped), for: .touchUpInside)
            
            let barButtonItem = UIBarButtonItem(customView: rightButton)
            
            tabBarController?.navigationItem.rightBarButtonItem = barButtonItem
            rightButton.snp.makeConstraints { make in
                make.width.equalTo(80)
                make.height.equalTo(32)
            }
            rightButton.addTouchFeedback()
        }
        
        
    }
    
    @objc private func paywallButtonTapped() {
        self.present(CreateElements.openPaywall(manager: purchaseManager), animated: true)
    }
    
    private func setupUI() {
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        collection.reloadData()
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
        let generateVC = GenerateVideoViewController(model: model, image: image, index: selectedIndex)
        print(image.count)
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

extension CreateViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.effectsArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.layer.cornerRadius = 20
        cell.backgroundColor = .white.withAlphaComponent(0.08)
        
        let videoName: String
        switch indexPath.row {
        case 0: videoName = "levitate_it1"
        case 1: videoName = "decapitate_it1"
        case 2: videoName = "eye-pop_it1"
        case 3: videoName = "Inflate_it1"
        case 4: videoName = "Melt_it1"
        case 5: videoName = "explode_it1"
        case 6: videoName = "Squish_it1"
        case 7: videoName = "Crush_it1"
        case 8: videoName = "Cake-ify_it1"
        case 9: videoName = "Ta-da_it1"
        case 10: videoName = "Deflate_it1"
        case 11: videoName = "crumble_it1"
        case 12: videoName = "dissolve_it1"
        default: videoName = "dissolve_it1"
        }
        
        // Проверяем наличие URL для видео
        if let urlVideo = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            let title = model.effectsArr[indexPath.row].effect
            cell.configure(with: urlVideo, title: title)
        }
        
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsInRow: CGFloat = 2
        let spacing: CGFloat = 5
        let totalSpacing = spacing * (numberOfItemsInRow + 1)
        let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsInRow
        let itemHeight: CGFloat = 200
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = model.effectsArr[indexPath.row].id
        self.cellTapped(index: indexPath.row)
    }
    
}
