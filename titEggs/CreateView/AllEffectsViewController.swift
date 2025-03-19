import UIKit
import Combine
import GSPlayer

class AllEffectsViewController: UIViewController {

    private var effects: [Effect]
    private var purchaseManager: PurchaseManager
    private var model: MainModel

    private let rightButton = PaywallButton()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .bgPrimary
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "VideoCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    init(effects: [Effect], purchaseManager: PurchaseManager, model: MainModel) {
        self.effects = effects
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupNavController()
    }

  private func setupNavController() {
      navigationController?.navigationBar.prefersLargeTitles = false
      navigationItem.hidesBackButton = true // Убираем стандартную кнопку назад

      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = .clear
      appearance.titleTextAttributes = [
          .foregroundColor: UIColor.white,
          .font: UIFont.appFont(.HeadlineRegular)
      ]

      navigationItem.standardAppearance = appearance
      navigationItem.scrollEdgeAppearance = appearance

      // Добавляем кастомную кнопку "назад" (стрелку влево)
      let backButton = UIBarButtonItem(
          image: UIImage(systemName: "chevron.left"), // Иконка стрелки
          style: .plain,
          target: self,
          action: #selector(onBackPressed)
      )
      backButton.tintColor = .white
      navigationItem.leftBarButtonItem = backButton

      // Добавляем кнопку PRO (если не куплено)
      if !purchaseManager.hasUnlockedPro {
          rightButton.addTarget(self, action: #selector(paywallButtonTapped), for: .touchUpInside)
          let barButtonItem = UIBarButtonItem(customView: rightButton)
          navigationItem.rightBarButtonItem = barButtonItem
          rightButton.snp.makeConstraints { make in
              make.width.equalTo(80)
              make.height.equalTo(32)
          }
          rightButton.addTouchFeedback()
      }
  }

  // Метод обработки нажатия на кнопку "назад"
  @objc private func onBackPressed() {
      navigationController?.popViewController(animated: true)
  }


    private func checkManager() {
        if purchaseManager.hasUnlockedPro {
            rightButton.alpha = 0
        } else {
            rightButton.alpha = 1
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
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource

extension AllEffectsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return effects.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
        cell.layer.cornerRadius = 20
        cell.backgroundColor = .white.withAlphaComponent(0.08)

        let effect = effects[indexPath.row]

        let label = UILabel()
        label.text = effect.effect
        label.textColor = .white
        label.font = .appFont(.BodyRegular)
        cell.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(15)
        }

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
            videoView.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview().inset(10)
                make.bottom.equalTo(label.snp.top).inset(-15)
            }
        }

        let url = URL(string: effect.previewSmall ?? "") ?? Bundle.main.url(forResource: "Melt_it1", withExtension: "mp4")!
        DispatchQueue.main.async {
            videoView.play(for: url)
            videoView.isMuted = true
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsInRow: CGFloat = 2
        let spacing: CGFloat = 12
        let totalSpacing = spacing * (numberOfItemsInRow + 1)
        let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsInRow
        let itemHeight = itemWidth * 1.35
        return CGSize(width: itemWidth, height: itemHeight)
    }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      let selectedEffect = effects[indexPath.row]
      if selectedEffect.categoryTitleEn == "Hug and Kiss" {
          let createImageVC = CreateImageViewController(
              purchaseManager: purchaseManager,
              model: model,
              publisher: PassthroughSubject<Bool, Never>(),
              effectID: selectedEffect.id,
              effectTitle: selectedEffect.title
          )
          navigationController?.pushViewController(createImageVC, animated: true)
      } else {
          let globalIndex = model.effectsArr.firstIndex(where: { $0.id == selectedEffect.id }) ?? 0
          navigationController?.pushViewController(
              PreviewEffectViewController(
                  model: model,
                  index: globalIndex,
                  purchaseManager: purchaseManager,
                  publisher: PassthroughSubject<Bool, Never>(),
                  ai: selectedEffect.ai
              ),
              animated: true
          )
      }
  }

}
