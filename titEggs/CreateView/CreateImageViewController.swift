import UIKit
import Photos
import Combine
import SnapKit
import SwiftUI

class CreateImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var purchaseManager: PurchaseManager
    var model: MainModel
    var publisher: PassthroughSubject<Bool, Never>
    var effectID: Int
    var effectTitle: String

    // Храним выбранные изображения, если нужно 2 (для splitMode).
    private var selectedImage1: UIImage?
    private var selectedImage2: UIImage?

    // Отслеживаем, для какой кнопки пользователь выбирает фото.
    private var currentButton: UIButton?

    private var isSplitMode = true {
        didSet {
            updateUIForMode()
            updateCreateButtonState()
        }
    }

    // MARK: - UI

    private let rightButton = PaywallButton()

    private let splitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Split images", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(onSplitTapped), for: .touchUpInside)
        return button
    }()

    private let singleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Single image", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(onSingleTapped), for: .touchUpInside)
        return button
    }()

    private let tabsStack = UIStackView()
    private let leftTabView = UIView()
    private let leftImageView = UIImageView()
    private let rightTabView = UIView()
    private let rightImageView = UIImageView()

    private let addPhotoButton1 = UIButton()
    private let addPhotoButton2 = UIButton()

    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create", for: .normal)
        button.isEnabled = false
        button.setTitleColor(UIColor(hex: "#FFEBCDB2").withAlphaComponent(0.7), for: .normal)
        button.backgroundColor = UIColor(hex: "#2C2C2C")
        button.layer.cornerRadius = 10
        return button
    }()

    // MARK: - Init

  init(purchaseManager: PurchaseManager,
          model: MainModel,
          publisher: PassthroughSubject<Bool, Never>,
          effectID: Int,
          effectTitle: String) {

         self.purchaseManager = purchaseManager
         self.model = model
         self.publisher = publisher
         self.effectID = effectID
         self.effectTitle = effectTitle

         super.init(nibName: nil, bundle: nil)
     }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupNavigationBar()
        setupModeButtons()
        setupTabs()
        setupAddPhotoArea()
        setupCreateButton()
        isSplitMode = true
    }

    // MARK: - Setup

  private func setupNavigationBar() {
      let titleLabel = UILabel()
      titleLabel.text = effectTitle
      titleLabel.textColor = .white
      titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
      titleLabel.textAlignment = .center

      navigationItem.titleView = titleLabel

      let backButton = UIBarButtonItem(
          image: UIImage(systemName: "chevron.left"),
          style: .plain,
          target: self,
          action: #selector(onBackPressed)
      )

      backButton.tintColor = .white
      navigationItem.leftBarButtonItem = backButton
      navigationItem.hidesBackButton = true

      if !purchaseManager.hasUnlockedPro {
          rightButton.addTarget(self, action: #selector(paywallButtonTapped), for: .touchUpInside)

          let barButtonItem = UIBarButtonItem(customView: rightButton)

          self.navigationItem.rightBarButtonItem = barButtonItem

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
     // showNewPaywall()
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
  // Метод обработки нажатия на кнопку "назад"
  @objc private func onBackPressed() {
      navigationController?.popViewController(animated: true)
  }


    private func setupModeButtons() {
        let modeStack = UIStackView(arrangedSubviews: [splitButton, singleButton])
        modeStack.axis = .horizontal
        modeStack.spacing = 10
        modeStack.distribution = .fillEqually
        view.addSubview(modeStack)

        modeStack.snp.makeConstraints { make in
          make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(46)
        }
    }

    private func setupTabs() {
        tabsStack.axis = .horizontal
        tabsStack.spacing = 12
        tabsStack.distribution = .fillProportionally
        view.addSubview(tabsStack)

        tabsStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(66)
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(86)
        }

        tabsStack.addArrangedSubview(leftTabView)
        tabsStack.addArrangedSubview(rightTabView)

        leftTabView.addSubview(leftImageView)
        leftImageView.contentMode = .scaleAspectFit
        leftImageView.clipsToBounds = true
        leftImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        rightTabView.addSubview(rightImageView)
        rightImageView.contentMode = .scaleAspectFit
        rightImageView.clipsToBounds = true
        rightImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAddPhotoArea() {
        configureAddPhotoButton(addPhotoButton1, title: "Add 1 photo")
        configureAddPhotoButton(addPhotoButton2, title: "Add 2 photo")

        let buttonStack = UIStackView(arrangedSubviews: [addPhotoButton1, addPhotoButton2])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually
        view.addSubview(buttonStack)

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(tabsStack.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(15)
        }
    }

    /// Настраиваем кнопку как "пустую" (плюс + подпись)
    private func configureAddPhotoButton(_ button: UIButton, title: String) {
        // Удаляем все сабвью, чтобы не дублировать, если вдруг вызываем метод повторно
        button.subviews.forEach { $0.removeFromSuperview() }

        // Настраиваем фон и скругления
        button.backgroundColor = UIColor(hex: "#2C2C2C")
        button.layer.cornerRadius = 10

        // Создаём вертикальный UIStackView
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        // Иконка "плюс"
        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.tintColor = .white
        plusIcon.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(plusIcon)

        // Текст под иконкой
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .center
        stackView.addArrangedSubview(label)

        button.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        plusIcon.snp.makeConstraints { make in
            make.height.width.equalTo(50)
        }

        // При нажатии открываем галерею
        button.addTarget(self, action: #selector(selectPhoto(_:)), for: .touchUpInside)
    }

    private func setupCreateButton() {
        view.addSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        // Обработчик нажатия
        createButton.addTarget(self, action: #selector(onCreateTapped), for: .touchUpInside)
    }

    // MARK: - Image Picker

  @objc private func selectPhoto(_ sender: UIButton) {
      currentButton = sender // Теперь точно знаем, какую кнопку обновлять

      DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }

          let picker = UIImagePickerController()
          picker.sourceType = .photoLibrary
          picker.delegate = self
          picker.modalPresentationStyle = .fullScreen

          // Проверяем и запрашиваем доступ перед открытием
          self.checkPhotoLibraryPermission { granted in
              if granted {
                  DispatchQueue.main.async {
                      self.present(picker, animated: true)
                  }
              } else {
                  self.showPermissionAlert()
              }
          }
      }
  }

  private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
      let status = PHPhotoLibrary.authorizationStatus()

      switch status {
      case .authorized:
          completion(true)
      case .notDetermined:
          PHPhotoLibrary.requestAuthorization { newStatus in
              DispatchQueue.main.async {
                  completion(newStatus == .authorized)
              }
          }
      default:
          completion(false)
      }
  }

  private func showPermissionAlert() {
      let alert = UIAlertController(
          title: "Access to Photos is Required",
          message: "Please allow access to your photos in Settings.",
          preferredStyle: .alert
      )

      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
          if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
          }
      }))

      present(alert, animated: true)
  }

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let selectedImage = info[.originalImage] as? UIImage {
          if currentButton == addPhotoButton1 {
              selectedImage1 = selectedImage
              configureButtonWithImage(addPhotoButton1, selectedImage)
          } else if currentButton == addPhotoButton2 {
              selectedImage2 = selectedImage
              configureButtonWithImage(addPhotoButton2, selectedImage)
          }
          updateCreateButtonState() // Обновляем доступность кнопки "Create"
      }
      picker.dismiss(animated: true, completion: nil)
  }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
  private func configureButtonWithImage(_ button: UIButton, _ image: UIImage) {
      button.subviews.forEach { $0.removeFromSuperview() }

      // Добавляем само изображение
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      button.addSubview(imageView)
      imageView.snp.makeConstraints { make in
          make.edges.equalToSuperview()
      }

      // Кнопка удаления (X)
      let closeButton = UIButton(type: .system)
      closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
      closeButton.tintColor = .white

      // Добавляем полупрозрачный ободок
      closeButton.layer.borderWidth = 1.5
      closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
      closeButton.layer.cornerRadius = 16
      closeButton.clipsToBounds = true

      // Обработчик нажатия
      closeButton.addTarget(self, action: #selector(onRemovePhoto(_:)), for: .touchUpInside)
      button.addSubview(closeButton)

      closeButton.snp.makeConstraints { make in
          make.top.equalToSuperview().offset(8)
          make.right.equalToSuperview().inset(8)
          make.width.height.equalTo(32)
      }
  }


    @objc private func onRemovePhoto(_ sender: UIButton) {
        guard let parentButton = sender.superview as? UIButton else { return }

        if parentButton == addPhotoButton1 {
            selectedImage1 = nil
            configureAddPhotoButton(addPhotoButton1, title: "Add 1 photo")
        } else if parentButton == addPhotoButton2 {
            selectedImage2 = nil
            configureAddPhotoButton(addPhotoButton2, title: "Add 2 photo")
        }
        updateCreateButtonState()
    }

    // MARK: - Активация/деактивация кнопки Create

    private func updateCreateButtonState() {
        if isSplitMode {
            // Нужны обе картинки
            if selectedImage1 != nil && selectedImage2 != nil {
                createButton.isEnabled = true
                createButton.backgroundColor = UIColor(hex: "#FFEBCD")
                createButton.setTitleColor(.black, for: .normal)
            } else {
                createButton.isEnabled = false
                createButton.backgroundColor = UIColor(hex: "#2C2C2C")
                createButton.setTitleColor(UIColor(hex: "#FFEBCDB2").withAlphaComponent(0.7), for: .normal)
            }
        } else {
            if selectedImage1 != nil {
                createButton.isEnabled = true
                createButton.backgroundColor = UIColor(hex: "#FFEBCD")
                createButton.setTitleColor(.black, for: .normal)
            } else {
                createButton.isEnabled = false
                createButton.backgroundColor = UIColor(hex: "#2C2C2C")
                createButton.setTitleColor(UIColor(hex: "#FFEBCDB2").withAlphaComponent(0.7), for: .normal)
            }
        }
    }

  @objc private func onCreateTapped() {
      if isSplitMode {
          // Для Split Mode передаём 2 изображения
          guard let img1 = selectedImage1,
                let img2 = selectedImage2,
                let data1 = img1.jpegData(compressionQuality: 1.0),
                let data2 = img2.jpegData(compressionQuality: 1.0) else {
              return
          }
          openGenerateVC(images: [data1, data2]) // Передаём массив
      } else {
          // Для Single Mode передаём одно изображение в массиве
          guard let img = selectedImage1,
                let data = img.jpegData(compressionQuality: 1.0) else {
              return
          }
          openGenerateVC(images: [data]) // Оборачиваем в массив
      }
  }

  private func openGenerateVC(images: [Data]) {
      let generateVC = GenerateVideoViewController(
          model: model,
          image: images, // Теперь передаётся всегда массив
          index: 0,
          publisher: publisher,
          video: nil, promptText: nil
      )
      generateVC.modalPresentationStyle = .fullScreen
      generateVC.modalTransitionStyle = .coverVertical
      if #available(iOS 13.0, *) {
          generateVC.isModalInPresentation = true
      }
      present(generateVC, animated: true)
  }


    // MARK: - Смена режима (Split / Single)

    @objc private func onSplitTapped() {
        isSplitMode = true
    }

    @objc private func onSingleTapped() {
        isSplitMode = false
    }

    // Обновляет внешний вид (примерно как раньше)
    private func updateUIForMode() {
        if isSplitMode {
            splitButton.backgroundColor = UIColor(hex: "#F5E1C0")
            splitButton.setTitleColor(.black, for: .normal)
            singleButton.backgroundColor = .bgTeriary
            singleButton.setTitleColor(.white, for: .normal)

            leftImageView.image = UIImage(named: "exampleSplit1")
            rightImageView.image = UIImage(named: "exampleSplit2")
        } else {
            splitButton.backgroundColor = .bgTeriary
            splitButton.setTitleColor(.white, for: .normal)
            singleButton.backgroundColor = UIColor(hex: "#F5E1C0")
            singleButton.setTitleColor(.black, for: .normal)

            leftImageView.image = UIImage(named: "exampleSingle1")
            rightImageView.image = UIImage(named: "exampleSingle2")
        }

        // Перестраиваем размер кнопок Add
        guard let buttonStack = view.subviews.first(where: {
            $0 is UIStackView && $0.subviews.contains(addPhotoButton2)
        }) as? UIStackView else {
            return
        }

        if isSplitMode {
            addPhotoButton2.isHidden = false
            addPhotoButton1.snp.remakeConstraints { make in
                make.height.equalTo(180)
            }
            addPhotoButton2.snp.remakeConstraints { make in
                make.height.equalTo(180)
            }

            buttonStack.snp.remakeConstraints { make in
                make.top.equalTo(tabsStack.snp.bottom).offset(50)
                make.left.right.equalToSuperview().inset(15)
                make.height.equalTo(180)
            }
        } else {
            addPhotoButton2.isHidden = true
            addPhotoButton1.snp.remakeConstraints { make in
                make.height.equalTo(360)
            }

            buttonStack.snp.remakeConstraints { make in
                make.top.equalTo(tabsStack.snp.bottom).offset(50)
                make.left.right.equalToSuperview().inset(15)
                make.height.equalTo(360)
            }
        }
        view.layoutIfNeeded()
    }
}

// MARK: - UIColor + Hex

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#"), let index = hex.firstIndex(of: "#") {
            scanner.currentIndex = hex.index(after: index)
        }
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - SwiftUI Preview

@available(iOS 13.0, *)
struct CreateImageViewController_Preview: PreviewProvider {
    static var previews: some View {
        ViewControllerPreview {
            CreateImageViewController(
                purchaseManager: PurchaseManager(),
                model: MainModel(), publisher: PassthroughSubject<Bool, Never>(),
                effectID: 1,
                effectTitle: "ok"
            )
        }
    }
}

struct ViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController

    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }

    func makeUIViewController(context: Context) -> ViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
