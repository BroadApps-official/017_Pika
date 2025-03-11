import UIKit
import SnapKit

class PromptViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  var purchaseManager: PurchaseManager
  var model: MainModel
  
    private let rightButton = PaywallButton()

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
        textView.text = "Enter your request"
        textView.textColor = .white.withAlphaComponent(0.4)
        textView.font = .appFont(.BodyRegular)
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return textView
    }()

    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create", for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
        button.backgroundColor = .white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .appFont(.HeadlineRegular)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupNavController()
        self.title = "Promt"
    }

  override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)

      self.title = "Prompt"

      setupNavController()
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

  init(purchaseManager: PurchaseManager, model: MainModel) {
      self.purchaseManager = purchaseManager
      self.model = model
      super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
    private func setupUI() {
        view.addSubview(uploadView)
        uploadView.addSubview(uploadIcon)
        uploadView.addSubview(uploadLabel)
        uploadView.addSubview(uploadButton)

        view.addSubview(requestTextView)
        view.addSubview(createButton)

        uploadView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(140)
        }

        uploadIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        uploadLabel.snp.makeConstraints { make in
            make.top.equalTo(uploadIcon.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
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

    @objc private func uploadTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func paywallButtonTapped() {
      let paywallVC = NewPaywallViewController(manager: purchaseManager)
        paywallVC.modalPresentationStyle = .fullScreen
        present(paywallVC, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
