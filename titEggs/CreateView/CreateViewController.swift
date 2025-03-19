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
import GSPlayer

class CreateViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    private let rightButton = PaywallButton()

    var purchaseManager: PurchaseManager
    var model: MainModel

    private var categories: [(title: String, effects: [Effect])] = []

    private var selectedIndex = 0

    private lazy var cancellable = [AnyCancellable]()
    private var publisher = PassthroughSubject<Bool, Never>()

    private lazy var activity: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .primary
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 16
        return view
    }()

  private lazy var collection: UICollectionView = {
          let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
              return self.createHorizontalSectionLayout()
          }
          let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
          collection.backgroundColor = .bgPrimary
          collection.showsVerticalScrollIndicator = false
          collection.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: "VideoCollectionViewCell")
          collection.register(
              CreateHeaderView.self,
              forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
              withReuseIdentifier: CreateHeaderView.reuseIdentifier
          )
          collection.alpha = 0
          collection.delegate = self
          collection.dataSource = self
          return collection
      }()

    // MARK: - Init

    init(purchaseManager: PurchaseManager, model: MainModel) {
        self.purchaseManager = purchaseManager
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavController()
        checkManager()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
      if !checkAppVersion() {
          openUpdateAlert()
      }
        loadArr()
        subscribe()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupNavController()
    }

  private func openUpdateAlert() {
      let alert = UIAlertController(title: "Attention", message: "Please update the app for more stable performance", preferredStyle: .alert)
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
      alert.addAction(cancelAction)

      let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
          let url = URL(string: "https://itunes.apple.com/us/app/preview-effects/id6737900240")!
          UIApplication.shared.open(url)
      }
      alert.addAction(updateAction)

      self.present(alert, animated: true)
  }


  private func checkAppVersion() -> Bool {
         guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
             return false
         }

      let minimumRequiredVersion = appVersion

         if compareVersion(currentVersion, with: minimumRequiredVersion) == .orderedAscending {
             return false
         }
         return true
  }

  private func compareVersion(_ version1: String, with version2: String) -> ComparisonResult {
      return version1.compare(version2, options: .numeric)
  }
  private func loadArr() {
         collection.alpha = 0
         model.loadEffectArr { [weak self] in
             guard let self = self else { return }

             if self.model.effectsArr.count > 0 {
                 var groupedEffects = Dictionary(grouping: self.model.effectsArr) { $0.categoryTitleEn }

                 self.categories = groupedEffects.map { (key, value) in
                     return (title: key, effects: value)
                 }.sorted { category1, category2 in
                     return category1.title == "Hug and Kiss" ? true : false
                 }

                 UIView.animate(withDuration: 0.3) {
                     self.collection.alpha = 1
                     self.view.layoutIfNeeded()
                 }
                 self.activity.removeFromSuperview()
                 self.collection.reloadData()
             }
         }
     }
    // MARK: - Purchases

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

        publisher.sink { result in
            print("ПАБЛИШЕР У КРЕЙТ ВС СДЕЛАН")
            if result == true {
                if let tabBarController = self.tabBarController {
                    tabBarController.selectedIndex = 2
                }
            }
        }
        .store(in: &cancellable)
    }

    // MARK: - UI Setup

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

        // Кнопка PRO (если не куплен)
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

    private func setupUI() {
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        collection.reloadData()

        view.addSubview(activity)
        activity.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.width.equalTo(64)
        }
        activity.startAnimating()
    }

    // MARK: - Selecting Photo -> Generate

    private func cellTapped(index: Int) {
        let alert = UIAlertController(
            title: "Select action",
            message: "Add a photo so we can do a cool effect with it",
            preferredStyle: .actionSheet
        )

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

        // Поповер для iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        self.present(alert, animated: true)
    }

    private func selectedPhoto(image: Data) {
        openGenerateVC(image: image)
    }

    private func openGenerateVC(image: Data) {
        let generateVC = GenerateVideoViewController(
            model: model,
            image: image,
            index: selectedIndex,
            publisher: publisher,
            video: nil, promptText: nil
        )
        generateVC.modalPresentationStyle = .fullScreen
        generateVC.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            generateVC.isModalInPresentation = true
        }
        self.present(generateVC, animated: true)
    }

  private func createHorizontalSectionLayout() -> NSCollectionLayoutSection {
      let itemWidth = (UIScreen.main.bounds.width - 45) / 2
      let itemSize = NSCollectionLayoutSize(
          widthDimension: .absolute(itemWidth),
          heightDimension: .absolute(220)
      )
      let item = NSCollectionLayoutItem(layoutSize: itemSize)

      let groupSize = NSCollectionLayoutSize(
          widthDimension: .estimated(itemWidth * 2),
          heightDimension: .absolute(220)
      )
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

      let section = NSCollectionLayoutSection(group: group)
      section.orthogonalScrollingBehavior = .continuous
      section.interGroupSpacing = 15
      section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 20, trailing: 15)

      let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
      let header = NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: headerSize,
          elementKind: UICollectionView.elementKindSectionHeader,
          alignment: .top
      )
      section.boundarySupplementaryItems = [header]

      return section
  }


  private func openCategoryScreen(category: (title: String, effects: [Effect])?) {
      guard let category = category else { return }

      let allEffectsVC = AllEffectsViewController(
          effects: category.effects,
          purchaseManager: purchaseManager,
          model: model
      )
      allEffectsVC.title = category.title
      navigationController?.pushViewController(allEffectsVC, animated: true)
  }

    // MARK: - UIImagePicker

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

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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

// MARK: - UICollectionView Extensions

extension CreateViewController: UICollectionViewDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
      return categories.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
      return categories[section].effects.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "VideoCollectionViewCell",
            for: indexPath
        )

        // Очищаем сабвью, чтобы не было наложений
        cell.subviews.forEach { $0.removeFromSuperview() }
        cell.layer.cornerRadius = 20
        cell.backgroundColor = .white.withAlphaComponent(0.08)

      let effect = categories[indexPath.section].effects[indexPath.row]

        // Лейбл
        let label = UILabel()
        label.text = effect.effect
        label.textColor = .white
        label.font = .appFont(.BodyRegular)

        // Добавляем VideoPlayerView для предпросмотра
        var videoView: VideoPlayerView
        if let existingVideoView = cell.viewWithTag(100) as? VideoPlayerView {
            videoView = existingVideoView
        } else {
            videoView = VideoPlayerView()
            videoView.layer.cornerRadius = 10
            videoView.clipsToBounds = true
            videoView.contentMode = .center
            videoView.playerLayer.videoGravity = .resizeAspectFill
            videoView.tag = 100
            videoView.isMuted = true
            videoView.replay(resetCount: true)
            cell.addSubview(videoView)
        }

        // Добавляем subviews и расставляем констрейнты
        cell.addSubview(label)

        videoView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview().inset(10)
            make.bottom.equalTo(label.snp.top).offset(-15)
        }
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(15)
        }

        // Загружаем превью-видео
        let url = URL(string: effect.previewSmall ?? "") ??
                  Bundle.main.url(forResource: "Melt_it1", withExtension: "mp4")!

        DispatchQueue.main.async {
            videoView.play(for: url)
            videoView.isMuted = true
        }

        return cell
    }

    // Заголовок секции
  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {

      guard kind == UICollectionView.elementKindSectionHeader else {
          return UICollectionReusableView()
      }

      let header = collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: CreateHeaderView.reuseIdentifier,
          for: indexPath
      ) as! CreateHeaderView

      // Берем нужную категорию из данных
    let categoryTitle = categories[indexPath.section].title
       header.titleLabel.text = categoryTitle
       header.seeAllButton.isHidden = false


    header.onSeeAllTapped = { [weak self] in
           self?.openCategoryScreen(category: self?.categories[indexPath.section])
       }

      return header
  }

    // Размер заголовка
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 40)
    }

    // Размер ячеек
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {

      let numberOfItemsInRow: CGFloat = 2
      let spacing: CGFloat = 12  // Подбираем отступы по макету
      let totalSpacing = spacing * (numberOfItemsInRow + 1)

      let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsInRow

      // Подбираем правильное соотношение ширины к высоте
      let itemHeight = itemWidth * 1.45
      return CGSize(width: itemWidth, height: itemHeight)
  }


    // Обработка нажатия на ячейку
  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {

      let effect = categories[indexPath.section].effects[indexPath.row]

      if categories[indexPath.section].title == "Hug and Kiss" {
          let createImageVC = CreateImageViewController(
              purchaseManager: purchaseManager,
              model: model,
              publisher: publisher,
              effectID: effect.id,
              effectTitle: effect.effect  
          )
          navigationController?.pushViewController(createImageVC, animated: true)
      } else {
          let globalIndex = model.effectsArr.firstIndex(where: { $0.id == effect.id }) ?? 0
          navigationController?.pushViewController(
              PreviewEffectViewController(
                  model: model,
                  index: globalIndex,
                  purchaseManager: purchaseManager,
                  publisher: publisher,
                  ai: effect.ai
              ),
              animated: true
          )
      }
  }
}

class CreateHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "CreateHeaderView"

    let titleLabel: UILabel = {
        let label = UILabel()
      label.font = .systemFont(ofSize: 20, weight: .heavy)
        label.textColor = .white
        return label
    }()

  let seeAllButton: UIButton = {
      let button = UIButton(type: .system)

      // Создание текста и иконки
      let title = "See all"
      let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
      let arrowImage = UIImage(systemName: "chevron.right", withConfiguration: symbolConfig)?
          .withTintColor(.white, renderingMode: .alwaysOriginal)

      // Установка атрибутированного текста
      button.setTitle(title, for: .normal)
      button.setTitleColor(.white, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)

      // Установка иконки
      button.setImage(arrowImage, for: .normal)
      button.tintColor = .white
      button.semanticContentAttribute = .forceRightToLeft // Иконка справа от текста

      // Стилизация кнопки
      button.layer.borderColor = UIColor.white.cgColor
      button.layer.borderWidth = 1
      button.layer.cornerRadius = 8
      button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
      button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4) // Отступ для иконки

      return button
  }()

    var onSeeAllTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(seeAllButton)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        seeAllButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)
    }

    @objc private func seeAllTapped() {
        onSeeAllTapped?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
