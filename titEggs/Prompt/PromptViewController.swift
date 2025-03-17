import UIKit
import Combine
import SnapKit

class PromptViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {

    var purchaseManager: PurchaseManager
    var model: MainModel

    private let rightButton = PaywallButton()
    private var selectedImage: UIImage? {
        didSet { updateUIState() }
    }

    private var promptText: String? {
        didSet { updateUIState() }
    }

    private let uploadView: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.08)
        view.layer.cornerRadius = 16
        return view
    }()

    private let uploadIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "photo_rectangle"))
        imageView.tintColor = .white.withAlphaComponent(0.6)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let uploadLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSAttributedString(
            string: "Upload or take a photo",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .font: UIFont.appFont(.BodyRegular),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        label.attributedText = attributedText
        label.textAlignment = .center
        return label
    }()

    private lazy var uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        return button
    }()

    private let requestTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .white.withAlphaComponent(0.08)
        textView.layer.cornerRadius = 16
        textView.text = "Use English for best results"
        textView.textColor = .white.withAlphaComponent(0.4)
        textView.font = .appFont(.BodyRegular)
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return textView
    }()

    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create", for: .normal)
        button.setTitleColor(UIColor(hex: "#FFEBCDB2").withAlphaComponent(0.7), for: .normal)
        button.backgroundColor = .white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 10
        button.isEnabled = false
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return button
    }()

    private let uploadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupNavController()
        title = "Prompt"

        requestTextView.delegate = self
        requestTextView.addDoneButtonOnKeyboard()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Prompt"
        setupNavController()
    }

  override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      resetInputFields()
  }

    // MARK: - Скрытие клавиатуры
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

  private func resetInputFields() {
      selectedImage = nil
      uploadImageView.image = nil
      uploadImageView.isHidden = true

      requestTextView.text = "Use English for best results"
      requestTextView.textColor = .white.withAlphaComponent(0.4)

      updateUIState()
  }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(uploadView)

        let uploadStackView = UIStackView(arrangedSubviews: [uploadIcon, uploadLabel])
        uploadStackView.axis = .vertical
        uploadStackView.alignment = .center
        uploadStackView.spacing = 8

        let uploadContentStackView = UIStackView(arrangedSubviews: [uploadImageView, uploadStackView])
        uploadContentStackView.axis = .horizontal
        uploadContentStackView.alignment = .center
        uploadContentStackView.spacing = 12

        uploadView.addSubview(uploadContentStackView)
        uploadView.addSubview(uploadButton)

        view.addSubview(requestTextView)
        view.addSubview(createButton)

        uploadView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(140)
        }

        uploadContentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(10)
        }

        uploadImageView.snp.makeConstraints { make in
            make.width.height.equalTo(120)
        }

        uploadIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        uploadLabel.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(200)
        }

        uploadButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        requestTextView.snp.makeConstraints { make in
            make.top.equalTo(uploadView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(163)
        }

        createButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }

    private func setupNavController() {
        tabBarController?.title = "Prompt"
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

    // MARK: - Paywall
    @objc private func paywallButtonTapped() {
        let paywallVC = NewPaywallViewController(manager: purchaseManager)
        paywallVC.modalPresentationStyle = .fullScreen
        present(paywallVC, animated: true)
    }

    // MARK: - Actions
    @objc private func uploadTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self

        let alert = UIAlertController(
            title: "Select action",
            message: "Add a photo so we can do a cool effect with it",
            preferredStyle: .actionSheet
        )

        let dynamicTextColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .white : .black
        }

        let photoAction = UIAlertAction(title: "Take a photo", style: .default) { _ in
            picker.sourceType = .camera
            self.present(picker, animated: true)
        }
        photoAction.setValue(dynamicTextColor, forKey: "titleTextColor")
        alert.addAction(photoAction)

        let galleryAction = UIAlertAction(title: "Select from gallery", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        }
        galleryAction.setValue(dynamicTextColor, forKey: "titleTextColor")
        alert.addAction(galleryAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(dynamicTextColor, forKey: "titleTextColor")
        alert.addAction(cancelAction)

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

        present(alert, animated: true)
    }

    @objc private func createTapped() {
        // Скрываем клавиатуру, если открыта
        view.endEditing(true)

        // Если нет подписки — открываем пейвол и не продолжаем
        guard purchaseManager.hasUnlockedPro else {
            paywallButtonTapped()
            return
        }

        guard let imageData = selectedImage?.pngData() else { return }
        openGenerateVC(images: [imageData])
    }

    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            selectedImage = image
            uploadImageView.image = image
            uploadImageView.isHidden = false
            uploadIcon.isHidden = false
            uploadLabel.isHidden = false
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - TextView Delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Use English for best results" {
            textView.text = ""
            textView.textColor = .white
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        promptText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - UI Updates
    private func updateUIState() {
        let isReady = selectedImage != nil && !(promptText?.isEmpty ?? true)
        createButton.isEnabled = isReady
        createButton.setTitleColor(isReady ? .black : UIColor(hex: "#FFEBCDB2").withAlphaComponent(0.7), for: .normal)
        createButton.backgroundColor = isReady ? UIColor(hex: "#FFEBCD") : .white.withAlphaComponent(0.08)
    }

    // MARK: - Open Generate VC
    private func openGenerateVC(images: [Data]) {
        let generateVC = GenerateVideoViewController(
            model: model,
            image: images,
            index: 0,
            publisher: PassthroughSubject(),
            video: nil,
            promptText: promptText
        )
        generateVC.modalPresentationStyle = .fullScreen
        present(generateVC, animated: true)
    }
}

// MARK: - Extension для добавления кнопки Done в UITextView
extension UITextView {
    func addDoneButtonOnKeyboard() {
        let doneToolbar = UIToolbar(frame: CGRect(
            x: 0, y: 0,
            width: UIScreen.main.bounds.width,
            height: 50
        ))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil,
                                        action: nil)
        let done = UIBarButtonItem(title: "Done",
                                   style: .done,
                                   target: self,
                                   action: #selector(self.endEditingForced))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.inputAccessoryView = doneToolbar
    }

    @objc private func endEditingForced() {
        self.resignFirstResponder()
    }
}
