//
//  MyVideosViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 06.11.2024.
//

import UIKit
import SnapKit
import Combine
import AVFoundation
import StoreKit
import Photos
import MobileCoreServices

class MyVideosViewController: UIViewController {
    
    private let rightButton = PaywallButton()
    
    var purchaseManager: PurchaseManager
    var model: MainModel
    
    private lazy var cancellable = [AnyCancellable]()
    
    private lazy var noVideoView = createNoView()
    
    private var publisher = PassthroughSubject<Bool, Never>()
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        layout.scrollDirection = .vertical
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "1")
        collection.backgroundColor = .clear
        collection.clipsToBounds = true
        collection.delegate = self
        collection.dataSource = self
        collection.showsVerticalScrollIndicator = false
        collection.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

        return collection
    }()

    private var selectIndex = 0
    
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
        checkManager()
        setupNavController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribe()
        view.backgroundColor = .bgPrimary
        setupNavController()
        setupUI()
        sheckVideos()
    }
    

    private func checkManager() {
        
        print(purchaseManager.hasUnlockedPro, "- есть или нет покупок")
        
        if purchaseManager.hasUnlockedPro {
            rightButton.alpha = 0
        } else {
            rightButton.alpha = 1
        }
    }
    
    private func subscribe() {
        buyPublisher
            .sink { _ in
                self.checkManager()
            }
            .store(in: &cancellable)
        
        model.publisherVideo
            .sink { _ in
                self.checkManager()
                self.sheckVideos()
            }
            .store(in: &cancellable)
    }
    
    private func setupNavController() {
        tabBarController?.title = "My Videos"
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
        if dynamicAppHud?.segment == "v1" {
            showNewPaywall()
        } else {
            self.present(CreateElements.openPaywall(manager: purchaseManager), animated: true)
        }
      //  showNewPaywall()
    }
    
    func showNewPaywall() {
        let paywallViewController = NewPaywallViewController(manager: purchaseManager)
        paywallViewController.modalPresentationStyle = .fullScreen
        paywallViewController.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            paywallViewController.isModalInPresentation = true
        }
        self.present(paywallViewController, animated: true)
    }
    
    private func sheckVideos() {
        if model.arr.count == 0 {
            collection.alpha = 0
            noVideoView.alpha = 1
            view.addSubview(noVideoView)
            noVideoView.snp.makeConstraints { make in
                make.height.equalTo(201)
                make.left.right.equalToSuperview().inset(15)
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        } else {
            noVideoView.removeFromSuperview()

            collection.alpha = 1
            noVideoView.alpha = 0
            collection.reloadData()
        }
    }
    
    private func setupUI() {
        
       
        collection.alpha = 0
        view.addSubview(collection)
        collection.snp.makeConstraints({ make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        })

    }
    
    private func createNoView() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let imageViewNil = UIImageView(image: .noVideo)
        view.addSubview(imageViewNil)
        imageViewNil.snp.makeConstraints { make in
            make.height.width.equalTo(64)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        let topLabel = UILabel()
        topLabel.text = "No Videos"
        topLabel.textColor = .white
        topLabel.font = .appFont(.Title3Emphasized)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageViewNil.snp.bottom).inset(-3)
        }
        
        let subLabel = UILabel()
        subLabel.text = "Create your first adorable video and surprise\neveryone!"
        subLabel.textColor = .white.withAlphaComponent(0.8)
        subLabel.font = .appFont(.FootnoteRegular)
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 2
        view.addSubview(subLabel)
        subLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topLabel.snp.bottom).inset(-3)
        }
        
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 10
        button.backgroundColor = .primary
        button.addTouchFeedback()
        button.setTitle("Create!", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .appFont(.BodyRegular)
        button.setImage(.burn.withRenderingMode(.alwaysOriginal).resize(targetSize: CGSize(width: 32, height: 32)), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(openCreatePage), for: .touchUpInside)
        
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.width.equalTo(122)
            make.centerX.equalToSuperview()
            make.top.equalTo(subLabel.snp.bottom).inset(-20)
        }
        
        return view
    }
    
    @objc private func openCreatePage() {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 0
        }
    }
    
    private func createGeneratingView() -> UIView {
        let viewLoad = UIView()
        viewLoad.layer.cornerRadius = 20
        viewLoad.backgroundColor = .black.withAlphaComponent(0.4)
        viewLoad.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        viewLoad.layer.borderWidth = 0.55
        
        let grayView = UIView()
        grayView.backgroundColor = UIColor(red: 37/255, green: 37/255, blue: 37/255, alpha: 0.55)
        grayView.layer.cornerRadius = 8
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark) // или .dark, .extraLight и т.д.
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 8
        blurView.clipsToBounds = true
        blurView.alpha = 0.9
        
        grayView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewLoad.addSubview(grayView)
        grayView.snp.makeConstraints { make in
            make.height.equalTo(72)
            make.left.right.equalToSuperview().inset(15)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        let progressView = UIActivityIndicatorView(style: .medium)
        progressView.color = .primary.withAlphaComponent(1)
        grayView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(10)
        }
        progressView.center = grayView.center
        progressView.startAnimating()
        
        let label = UILabel()
        label.text = "Generation usually\ntakes about a minute"
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = .appFont(.Caption2Regular)
        label.textColor = .white
        
        grayView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(10)
        }
        
        return viewLoad
    }
    
    private func createErrorView() -> UIView {
        let viewLoad = UIView()
        viewLoad.layer.cornerRadius = 20
        viewLoad.backgroundColor = .black.withAlphaComponent(0.4)
        viewLoad.layer.borderColor = UIColor(red: 236/255, green: 13/255, blue: 42/255, alpha: 1).cgColor
        viewLoad.layer.borderWidth = 0.55
        
        let grayView = UIView()
        grayView.backgroundColor = UIColor(red: 37/255, green: 37/255, blue: 37/255, alpha: 0.55)
        grayView.layer.cornerRadius = 8
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark) // или .dark, .extraLight и т.д.
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 8
        blurView.clipsToBounds = true
        blurView.alpha = 0.9
        
        grayView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewLoad.addSubview(grayView)
        grayView.snp.makeConstraints { make in
            make.height.equalTo(72)
            make.left.right.equalToSuperview().inset(15)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        let imageView = UIImageView(image: .errorVideo)
        grayView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(10)
        }
        
        let label = UILabel()
        label.text = "Generation error, tap\nto learn more"
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = .appFont(.Caption2Regular)
        label.textColor = .white
        
        grayView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(10)
        }
        
        return viewLoad
    }
    
    private func getImageForCurrentTheme(image: UIImage) -> UIImage {
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
    
    private func saveInGallery(index: Int) {

        let videoData: Data = model.arr[index].video ?? Data()
        

        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        do {

            try videoData.write(to: tempURL)
            
            // Запрашиваем разрешение на доступ к фото-библиотеке
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        // Если доступ разрешен, сохраняем видео в галерею
                        self.saveVideoToGallery(videoURL: tempURL)
                    case .denied, .restricted:
                        self.showErrorAlert()
                    case .notDetermined:
                        PHPhotoLibrary.requestAuthorization { status in
                            if status == .authorized {
                                self.saveVideoToGallery(videoURL: tempURL)
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
        } catch {
            self.showErrorAlert()
        }
    }

    private func saveVideoToGallery(videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            // Создаем запрос на добавление видео
            let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            creationRequest?.creationDate = Date()  // Устанавливаем дату создания видео
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.showSuccessAlert()
                } else {
                    self.showErrorAlert()
                }
            }
        }
    }

    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Error, video not saved to gallery", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)

        let retryAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.saveInGallery(index: self.selectIndex)
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

    
    private func saveToFiles(index: Int) {
        // Получаем данные из модели
        let videoData: Data = model.arr[index].video ?? Data()
        
        // Проверяем, что данные не пустые
        guard !videoData.isEmpty else {
            print("Видео отсутствует")
            return
        }
        
        // Создаем временный файл для данных видео
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        do {
            // Записываем данные в временный файл
            try videoData.write(to: tempURL)
            
            // Создаем Document Picker для сохранения файла
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            present(documentPicker, animated: true, completion: nil)
            
        } catch {
            showErrorAlertFiles()
        }
    }
    
    private func showErrorAlertFiles() {
        let alert = UIAlertController(title: "Error, video not saved to files", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)

        let retryAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.saveToFiles(index: self.selectIndex)
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
    
    private func delete() {
        let alertController = UIAlertController(title: "Delete this video?", message: "It will disappear from the history in the My Videos tab. You will not be able to restore it after deletion.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancel)
        
        let ok = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
            
            
            model.arr.remove(at: selectIndex)
            model.saveArr()
            model.publisherVideo.send(1)
            
            model.checkStatus()
            
        }
        alertController.addAction(ok)
        
        self.present(alertController, animated: true)
    }
    
    private func reloadVideo(index: Int) {
        var item = model.arr[index]
        
        item.generationID = nil 
        item.resultURL = nil
        item.status = ""
        
        model.arr[index] = item
        model.saveArr()
        openGenerateVC(video: item)
        
    }
    
    private func openGenerateVC(video: Video) {
      let generateVC = GenerateVideoViewController(model: self.model, image: video.image, index: video.effectID, publisher: publisher, video: video, promptText: nil)
        generateVC.modalPresentationStyle = .fullScreen
        generateVC.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            generateVC.isModalInPresentation = true
        }
        self.present(generateVC, animated: true)
    }
    
    @objc private func openErrorVideo(index: Int) {
        print(index)
        selectIndex = index
        let alert = UIAlertController(title: "Video generation error", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)
        
        let tryAgain = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.reloadVideo(index: index)
        }
        alert.addAction(tryAgain)
        
        let delete = UIAlertAction(title: "Delete Video", style: .destructive) { _ in
            self.delete()
        }
        alert.addAction(delete)
        
        let cancel = UIAlertAction(title: "Close", style: .cancel)
        alert.addAction(cancel)
        
        self.present(alert, animated: true)
    }
    

}


extension MyVideosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .white.withAlphaComponent(0.08)
        cell.layer.cornerRadius = 20
        cell.isUserInteractionEnabled = true
        
        let mainView = UIView()
        mainView.backgroundColor = .clear
        cell.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let item = model.arr[indexPath.row]
        
        let imageView = UIImageView(image: UIImage(data: item.image))
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFill
        
        mainView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview().inset(10)
            make.height.equalTo(128)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = item.effectName
        titleLabel.textColor = .white
        titleLabel.font = .appFont(.BodyRegular)
        
        mainView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
        
        let dateView = UIView()
        dateView.backgroundColor = .clear
        dateView.layer.cornerRadius = 6
        mainView.addSubview(dateView)
        dateView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().inset(15)
            make.height.equalTo(21)
            make.width.equalTo(56)
        }
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark) 
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 6
        blurView.clipsToBounds = true
        blurView.alpha = 0.55

        dateView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let dateLabel = UILabel()
        dateLabel.text = item.dataGenerate
        dateLabel.font = .appFont(.Caption2Regular)
        dateLabel.textColor = .white
        dateView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        if item.video == nil && item.status != "error" {
            let view = createGeneratingView()
            cell.addSubview(view)
            cell.isUserInteractionEnabled = false
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else if item.status == "error" {
            let view = createErrorView()
            cell.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            let imageViewPlay = UIImageView(image: .play)
            imageView.addSubview(imageViewPlay)
            imageViewPlay.snp.makeConstraints { make in
                make.height.width.equalTo(44)
                make.center.equalToSuperview()
            }
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
        print(14)
        self.selectIndex = indexPath.row
        if model.arr[indexPath.row].video != nil && model.arr[indexPath.row].status != "error" {
            self.navigationController?.pushViewController(OpenedViewController(model: model, index: indexPath.row), animated: true)
        }
        if model.arr[indexPath.row].status == "error" {
            self.openErrorVideo(index: indexPath.row)
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        
        self.selectIndex = indexPaths.first?.row ?? 0
        
        if model.arr[selectIndex].video != nil && model.arr[selectIndex].status != "error"  {
            let imageSave = getImageForCurrentTheme(image: UIImage.saveGallery)
            let firstAction = UIAction(title: "Save to gallery", image: imageSave.resize(targetSize: CGSize(width: 20, height: 20))) { _ in
                self.saveInGallery(index: indexPaths.first?.row ?? 0)
                print(self.selectIndex)
            }

            let imageSaveFiled =  getImageForCurrentTheme(image: UIImage.saveFiles)
            let secondAction = UIAction(title: "Save to files", image: imageSaveFiled.resize(targetSize: CGSize(width: 20, height: 44))) { _ in
                self.saveToFiles(index: self.selectIndex)
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
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                return menu
            }
        } else if model.arr[selectIndex].status == "error"   {

            let menu = UIMenu(title: "Video not load", children: [])
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                return menu
            }
            
        } else {
           
            let menu = UIMenu(title: "Video is loading", children: [])
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                return menu
            }
        }
    }

    

    
}


extension MyVideosViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Обработка завершения выбора, если нужно
        print("Видео сохранено в: \(urls.first?.path ?? "Unknown")")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Пользователь отменил выбор")
    }
}
