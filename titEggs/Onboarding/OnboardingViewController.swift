//
//  OnboardingViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import StoreKit
import AVFoundation
import AVKit
import GSPlayer

class OnboardingViewController: UIViewController {
    
    var paywall: PurchaseManager
    let network = NetWorking()
    
    init(paywall: PurchaseManager) {
        self.paywall = paywall
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private let arr: [OnbData] = [
    OnbData(image: "onboardingVideo1", topText: "Pick a photo &\nblow it up", botText: "Create unreal videos"),
    OnbData(image: "onboardingVideo2", topText: "Turn everything\nyou see", botText: "Quick and easy"),
    OnbData(image: "onbVideo3", topText: "Take a photo &\nCake-ify it", botText: "Surprise your friends"),
    OnbData(image: "onboardingImage4", topText: "Rate our app in\nthe AppStore", botText: "Lots of satisfied users")]
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPage = 0
        control.numberOfPages = arr.count
        control.currentPageIndicatorTintColor = .white
        control.isUserInteractionEnabled = false
        return control
    }()
    
    
    private lazy var nextButton = CreateElements.createPrimaryButton(title: "Continue")
    
    private var tap = 0
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collection.isPagingEnabled = true
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "1")
        collection.isUserInteractionEnabled = false
        collection.delegate = self
        collection.dataSource = self
        return collection
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEffects()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        
    }
    
    private func loadEffects() {
        network.loadEffectsArr { escaping in
            var arr: [URL] = []
            for i in escaping {
                if i.previewSmall != nil {
                    arr.append(URL(string: i.previewSmall ?? "")!)
                }
            }
            VideoPreloadManager.shared.set(waiting: arr)
        }
    }
    

    private func setupUI() {
        
        
        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        
        view.addSubview(nextButton)
        nextButton.addTouchFeedback()
        nextButton.addTarget(self, action: #selector(goNext), for: .touchUpInside)
        nextButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(pageControl.snp.top).inset(-10)
            make.height.equalTo(48)
        }
        
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).inset(-10)
        }
        
    }
    
    @objc private func goNext() {
        let nextIndex = min(pageControl.currentPage + 1, arr.count - 1)
        let indexPath = IndexPath(item: nextIndex, section: 0)
        print(indexPath, "tap index")
        collection.scrollToItem(at: indexPath, at: .left, animated: true)
        pageControl.currentPage = nextIndex
        tap += 1
        if indexPath.row != 3  {
            collection.reloadItems(at: [indexPath])
        }
        
        
        switch tap {
        case 4:
            rateApp()
        case 5:
            self.navigationController?.setViewControllers([NotifyOnbViewController(paywall: paywall)], animated: true)
        default:
            return
        }

    }
    
    @objc private func rateApp() {
        if #available(iOS 14, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                DispatchQueue.main.async {
                    AppStore.requestReview(in: scene)
                }
            }
        } else {
            let appID = "ID"
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(6737900240)?action=write-review") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    
}


extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
    
        let item = arr[indexPath.row]
        print(indexPath.row , "- тут нет бага ")
        
        
        
        if indexPath.row < 3   {
            
            
            var player = AVPlayer(url: URL(fileURLWithPath: Bundle.main.path(forResource: item.image, ofType: "mp4")!))
            player.isMuted = true
            
           print(indexPath.row, item.image, "тут видосы")
            
            // Создаем UIView для отображения видео
            let videoContainerView = UIView()
            cell.addSubview(videoContainerView)
            videoContainerView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(videoContainerView.snp.width).multipliedBy(3.0 / 2.0)
            }
            
            // Создаем AVPlayerLayer и добавляем его в videoContainerView
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = videoContainerView.bounds
            playerLayer.videoGravity = .resizeAspectFill
            videoContainerView.layer.addSublayer(playerLayer)
            
            DispatchQueue.main.async {
                playerLayer.frame = videoContainerView.bounds
            }
            
            // Добавляем зацикливание видео
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
            }
            
            // Запускаем воспроизведение
            player.play()
            DispatchQueue.main.async {
                playerLayer.frame = videoContainerView.bounds
            }
            
        } else {
            print(indexPath.row, "rew")
            let imageView = UIImageView(image: UIImage(named: item.image))
            imageView.contentMode = .scaleAspectFill
            cell.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(imageView.snp.width).multipliedBy(3.0/2.0)
            }
        }
        
       
        
        let shadowImageView = UIImageView(image: .onbShadow)
        shadowImageView.contentMode = .scaleAspectFill
        cell.addSubview(shadowImageView)
        shadowImageView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(cell.snp.height).multipliedBy(1.0 / 3.0)
        }
        
        
        let botLabel = UILabel()
        botLabel.textColor = .white.withAlphaComponent(0.6)
        botLabel.text = item.botText
        botLabel.font = .appFont(.BodyRegular)
        shadowImageView.addSubview(botLabel)
        botLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(10)
        }
        
        let topLabel = UILabel()
        topLabel.numberOfLines = 2
        topLabel.text = item.topText
        topLabel.textAlignment = .center
        topLabel.font = .appFont(.LargeTitleEmphasized)
        topLabel.textColor = .white
        shadowImageView.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(botLabel.snp.top)
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = pageIndex
    }
}
