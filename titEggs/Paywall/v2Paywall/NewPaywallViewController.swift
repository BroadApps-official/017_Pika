//
//  NewPaywallViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 16.12.2024.
//

import UIKit
import StoreKit
import WebKit
import ApphudSDK
import AVFoundation
import AVKit
import FacebookCore

class NewPaywallViewController: UIViewController {
    
    private let manager:PurchaseManager
    private lazy var products: [ApphudProduct] = []
    
    init(manager: PurchaseManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var closePaywall: UIButton = {
        let button = UIButton(type: .system)
        button.setBackgroundImage(.closePaywall, for: .normal)
        button.alpha = 0
        return button
    }()
    
    private lazy var progressView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .primary
        return view
    }()
    
    private var timer: Timer?
    
    private lazy var continueButton = CreateElements.createPrimaryButton(title: "Continue")
    
    private lazy var shadowImageView = UIImageView(image: .shadowPaywall)
    
    private lazy var allPlansButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View all plans", for: .normal)
        button.titleLabel?.font = .appFont(.Caption1Regular)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Unreal videos with\nPRO"
        label.font = .appFont(.Title1Emphasized)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var activity: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .primary
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var policyButton = createMiniButtons(title: "Privacy Policy", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    private lazy var termsButton = createMiniButtons(title: "Terms of Use", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    private lazy var restoreButton = createMiniButtons(title: "Restore Purchases", color: .white.withAlphaComponent(0.6), font: .appFont(.Caption1Regular), isACancelAnytime: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupTimer()
        setupUI()
        someMethod()
    }
    
    private func someMethod() {
        Task {
            await loadProd()
        }
    }
    
    private func loadProd() async {
        await loadProducts()
    }
    
    
    private func loadProducts() async {
        // Ожидаем, пока массив products будет содержать 2 элемента
        while manager.productsApphud.count < 1 {
            await Task.sleep(500_000_000)
        }
        self.products = manager.productsApphud
        UIView.animate(withDuration: 0.3) {
            self.continueButton.alpha = 1
            self.progressView.stopAnimating()
        }
    }
      
    private func createMiniButtons(title: String, color: UIColor, font: UIFont, isACancelAnytime: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        button.setTitleColor(color, for: .normal)
        if isACancelAnytime {
            button.setImage(.cancelAnyTimeIco.withRenderingMode(.alwaysTemplate).resize(targetSize: CGSize(width: 24, height: 24)), for: .normal)
            button.tintColor = color
        }
        return button
    }

    
    private func setupUI() {
        
        guard let path = Bundle.main.path(forResource: "Paywall", ofType: "mp4") else {
            print("Video not found")
            return
        }

        let player = AVPlayer(url: URL(fileURLWithPath: path))
        player.isMuted = true

        // Создаем контейнер для видео
        let videoContainerView = UIView()
        videoContainerView.clipsToBounds = false
        view.addSubview(videoContainerView)
        videoContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(487)
        }

        // Создаем AVPlayerLayer и добавляем его в videoContainerView
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        videoContainerView.layer.addSublayer(playerLayer)

        // Обновляем размер слоя после применения ограничений
        view.layoutIfNeeded()
        playerLayer.frame = videoContainerView.bounds

        // Добавляем зацикливание видео
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }

        // Запускаем воспроизведение
        player.play()

        // Создаем изображение тени и добавляем поверх видео
        
        shadowImageView.clipsToBounds = false
        view.addSubview(shadowImageView)
        view.bringSubviewToFront(shadowImageView) // Убедитесь, что тень на переднем плане
        shadowImageView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(3 / 5.0)
            make.height.lessThanOrEqualTo(600)
        }

        view.layoutIfNeeded()
        
        view.addSubview(policyButton)
        policyButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        view.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.centerX.equalToSuperview()
        }
        
        view.addSubview(termsButton)
        termsButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        policyButton.addTarget(self, action: #selector(openPolicy), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restore), for: .touchUpInside)
        
        
        view.addSubview(activity)
        activity.stopAnimating()
        activity.snp.makeConstraints { make in
            make.height.width.equalTo(60)
            make.center.equalToSuperview()
        }
        activity.center = view.center
        
        view.addSubview(closePaywall)
        closePaywall.addTarget(self, action: #selector(close), for: .touchUpInside)
        closePaywall.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(39)
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        view.addSubview(continueButton)
        continueButton.addTarget(self, action: #selector(buy), for: .touchUpInside)
        continueButton.alpha = 0
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(48)
            make.bottom.equalTo(restoreButton.snp.top).inset(-15)
        }
        
        view.addSubview(progressView)
        progressView.startAnimating()
        progressView.snp.makeConstraints { make in
            make.center.equalTo(continueButton)
        }
        
        view.addSubview(allPlansButton)
        allPlansButton.addTarget(self, action: #selector(openAll), for: .touchUpInside)
        allPlansButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).inset(-15)
        }
        
        let topLabel = UILabel()
        topLabel.text = "$0.87 / week, billed annually at $19.99"
        topLabel.textColor = .white.withAlphaComponent(0.6)
        topLabel.font = .appFont(.SubheadlineRegular)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.bottom.equalTo(allPlansButton.snp.top).inset(-15)
            make.centerX.equalToSuperview()
        }
        
        let mainLabel = UILabel()
        mainLabel.text = "Get exclusive access\nwith PRO"
        mainLabel.textColor = .white
        mainLabel.font = .appFont(.Title1Emphasized)
        mainLabel.textAlignment = .center
        mainLabel.numberOfLines = 2
        view.addSubview(mainLabel)
        mainLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(topLabel.snp.top).inset(-15)
        }
        
        
    }
    
    @objc private func openAll() {
        let vc = AllPaywallViewController(manager: manager)

        // Устанавливаем стиль модального представления
        vc.modalPresentationStyle = .pageSheet

        // Настраиваем размер
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [
                .custom { context in
                    return context.maximumDetentValue * 0.7 // 70% высоты экрана
                }
            ]
            sheet.prefersGrabberVisible = true // Опционально: Добавить ручку для удобства
        }

        present(vc, animated: true, completion: nil)
    }

    
    @objc private func buy() {
        UIView.animate(withDuration: 0.3) {
            self.activity.startAnimating()
        }
        Task {
            do {
                let productToPurchase = products[0]
                manager.startPurchase(produst: productToPurchase) { result in
                    if result == true {
                        
                        let parameters: [AppEvents.ParameterName: Any] = [
                            .init("product_id"): productToPurchase.skProduct?.productIdentifier ?? "no id", // Уникальный ID продукта
                            .init("price"): productToPurchase.skProduct?.price.doubleValue ?? 0.0, // Цена продукта
                            .init("currency"): productToPurchase.skProduct?.priceLocale.currencySymbol ?? "$" // Валюта
                        ]
                        AppEvents.shared.logEvent(AppEvents.Name("subscriptionPurchase_completed"), parameters: parameters)
                        
                        UserDefaults.standard.setValue("1000", forKey: "amountTokens")
                        UserDefaults.standard.setValue("1000", forKey: "alltokens")
                        self.dismiss(animated: true)
                    }
                    
                    UIView.animate(withDuration: 0.3) {
                        self.activity.stopAnimating()
                    }
                    
                }
            }
        }
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
            UIView.animate(withDuration: 0.3) {
                self.closePaywall.alpha = 1
            }
            self.timer?.invalidate()
        })
    }
    
    @objc private func openPolicy() {
        let webVC = WebViewController()
        webVC.urlString = "https://www.termsfeed.com/live/b1287ca9-a8f5-49d4-ab0c-82f9f8fec119"
        present(webVC, animated: true, completion: nil)
    }
    
    @objc private func openTerms() {
        let webVC = WebViewController()
        webVC.urlString = "https://www.termsfeed.com/live/84172d38-c955-48c8-bad2-34beb03770c9"
        present(webVC, animated: true, completion: nil)
    }
    
    @objc private func close() {
        self.dismiss(animated: true)
    }
    
    @objc private func restore() {
        UIView.animate(withDuration: 0.3) {
            self.activity.startAnimating()
        }
            
        manager.restorePurchase { result in
            if result == true {
                self.dismiss(animated: true)
            }
            
            UIView.animate(withDuration: 0.3) {
                self.activity.stopAnimating()
            }
            
        }
    }
   

}
