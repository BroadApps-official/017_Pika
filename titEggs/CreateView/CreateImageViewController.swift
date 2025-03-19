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

    private var selectedImage1: UIImage?
    private var selectedImage2: UIImage?
    private let photoContainer1 = UIView()
    private let photoContainer2 = UIView()

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
        tabsStack.distribution = .fillEqually
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
        configurePhotoContainer(photoContainer1, title: "Add 1 photo")
        configurePhotoContainer(photoContainer2, title: "Add 2 photo")

        let containerStack = UIStackView(arrangedSubviews: [photoContainer1, photoContainer2])
        containerStack.axis = .horizontal
        containerStack.spacing = 10
        containerStack.distribution = .fillEqually
        view.addSubview(containerStack)

        containerStack.snp.makeConstraints { make in
            make.top.equalTo(tabsStack.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(180)
        }
    }

    private func configurePhotoContainer(_ container: UIView, title: String) {
        container.subviews.forEach { $0.removeFromSuperview() }
        
        container.backgroundColor = UIColor(hex: "#2C2C2C")
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        
        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.tintColor = .white
        plusIcon.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(plusIcon)
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .center
        stackView.addArrangedSubview(label)
        
        container.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        plusIcon.snp.makeConstraints { make in
            make.height.width.equalTo(50)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectPhoto(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
    }

    private func configureAddPhotoButton(_ button: UIButton, title: String) {
        button.subviews.forEach { $0.removeFromSuperview() }

        button.backgroundColor = UIColor(hex: "#2C2C2C")
        button.layer.cornerRadius = 10

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.tintColor = .white
        plusIcon.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(plusIcon)

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

        button.addTarget(self, action: #selector(selectPhoto(_:)), for: .touchUpInside)
    }

    private func setupCreateButton() {
        view.addSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        createButton.addTarget(self, action: #selector(onCreateTapped), for: .touchUpInside)
    }

    // MARK: - Image Picker

    @objc private func selectPhoto(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        currentButton = (tappedView == photoContainer1) ? addPhotoButton1 : addPhotoButton2
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        
        checkPhotoLibraryPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                DispatchQueue.main.async {
                    self.present(picker, animated: true)
                }
            } else {
                self.showPermissionAlert()
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
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let selectedImage = info[.originalImage] as? UIImage else { return }
            
            DispatchQueue.main.async {
                if self.currentButton == self.addPhotoButton1 {
                    self.selectedImage1 = selectedImage
                    self.updatePhotoContainer(self.photoContainer1, with: selectedImage)
                } else if self.currentButton == self.addPhotoButton2 {
                    self.selectedImage2 = selectedImage
                    self.updatePhotoContainer(self.photoContainer2, with: selectedImage)
                }
                self.updateCreateButtonState()
            }
        }
    }

    private func updatePhotoContainer(_ container: UIView, with image: UIImage) {
        container.subviews.forEach { $0.removeFromSuperview() }
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        container.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = .black.withAlphaComponent(0.3)
        closeButton.layer.cornerRadius = 16
        closeButton.clipsToBounds = true
        container.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.right.equalToSuperview().inset(8)
            make.width.height.equalTo(32)
        }
        
        closeButton.addTarget(self, action: #selector(removePhoto(_:)), for: .touchUpInside)
    }

    @objc private func removePhoto(_ sender: UIButton) {
        guard let container = sender.superview else { return }
        
        if container == photoContainer1 {
            selectedImage1 = nil
            configurePhotoContainer(photoContainer1, title: "Add 1 photo")
        } else if container == photoContainer2 {
            selectedImage2 = nil
            configurePhotoContainer(photoContainer2, title: "Add 2 photo")
        }
        
        updateCreateButtonState()
    }

    // MARK: - Активация/деактивация кнопки Create

    private func updateCreateButtonState() {
        if isSplitMode {
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

    // MARK: - Действия по кнопкам

    @objc private func onCreateTapped() {
        view.endEditing(true)
        guard purchaseManager.hasUnlockedPro else {
            showNewPaywall()
            return
        }

        var finalImageData: Data?

        if isSplitMode {
            guard let img1 = selectedImage1,
                  let img2 = selectedImage2,
                  let combinedImage = combineImages(img1, img2),
                  let combinedData = combinedImage.jpegData(compressionQuality: 0.8) else {
                print("❌ Ошибка при объединении изображений")
                return
            }
            finalImageData = combinedData
            print("📸 Создано объединенное изображение размером: \(combinedData.count) байт")
        } else {
            guard let img = selectedImage1,
                  let data = img.jpegData(compressionQuality: 0.8) else {
                print("❌ Ошибка при подготовке изображения")
                return
            }
            finalImageData = data
            print("📸 Подготовлено одиночное изображение размером: \(data.count) байт")
        }

        guard let imageData = finalImageData else { return }

        openGenerateVC(images: imageData)
    }

    private func openGenerateVC(images: Data) {
        let generateVC = GenerateVideoViewController(
            model: model,
            image: images,
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

    // Обновленный метод combineImages для лучшего результата
    private func combineImages(_ image1: UIImage, _ image2: UIImage) -> UIImage? {
        let maxWidth: CGFloat = 3800
        let maxHeight: CGFloat = 2300
        
        // Вычисляем размеры для итогового изображения
        let targetHeight = maxHeight / 3
        let targetWidth = targetHeight * (16/9) // Поддерживаем соотношение сторон 16:9
        
        // Создаем контекст для объединенного изображения
        let finalSize = CGSize(width: targetWidth * 2, height: targetHeight)
        
        UIGraphicsBeginImageContextWithOptions(finalSize, false, 1.0)
        
        // Функция для масштабирования и отрисовки изображения
        func drawImage(_ image: UIImage, in rect: CGRect) {
            // Масштабируем изображение, сохраняя пропорции
            let aspectRatio = image.size.width / image.size.height
            var drawRect = rect
            
            if aspectRatio > rect.width / rect.height {
                let newHeight = rect.width / aspectRatio
                drawRect.origin.y += (rect.height - newHeight) / 2
                drawRect.size.height = newHeight
            } else {
                let newWidth = rect.height * aspectRatio
                drawRect.origin.x += (rect.width - newWidth) / 2
                drawRect.size.width = newWidth
            }
            
            image.draw(in: drawRect)
        }
        
        // Рисуем изображения
        let rect1 = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        let rect2 = CGRect(x: targetWidth, y: 0, width: targetWidth, height: targetHeight)
        
        drawImage(image1, in: rect1)
        drawImage(image2, in: rect2)
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        print("📐 Размеры объединенного изображения: \(finalSize.width) x \(finalSize.height)")
        return combinedImage
    }

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
            
            photoContainer2.isHidden = false
            
            photoContainer1.snp.remakeConstraints { make in
                make.height.equalTo(180)
            }
            photoContainer2.snp.remakeConstraints { make in
                make.height.equalTo(180)
            }
        } else {
            splitButton.backgroundColor = .bgTeriary
            splitButton.setTitleColor(.white, for: .normal)
            singleButton.backgroundColor = UIColor(hex: "#F5E1C0")
            singleButton.setTitleColor(.black, for: .normal)

            leftImageView.image = UIImage(named: "exampleSingle1")
            rightImageView.image = UIImage(named: "exampleSingle2")
            
            photoContainer2.isHidden = true
            
            let squareSize = UIScreen.main.bounds.width - 30
            photoContainer1.snp.remakeConstraints { make in
                make.height.equalTo(squareSize)
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

extension UITextField {
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0,
                                                              y: 0,
                                                              width: UIScreen.main.bounds.width,
                                                              height: 50))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil,
                                        action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(self.doneButtonAction))
        let items = [flexSpace, done]
        doneToolbar.items = items
        self.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}

// MARK: - SwiftUI Preview

@available(iOS 13.0, *)
struct CreateImageViewController_Preview: PreviewProvider {
    static var previews: some View {
        ViewControllerPreview {
            CreateImageViewController(
                purchaseManager: PurchaseManager(),
                model: MainModel(),
                publisher: PassthroughSubject<Bool, Never>(),
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
