//
//  TokenPaywallViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 09.12.2024.
//

import UIKit
import StoreKit
import WebKit
import ApphudSDK
import AVFoundation
import AVKit
import FacebookCore

class TokenPaywallViewController: UIViewController {
    
    let model: MainModel
    
    init(model: MainModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private lazy var closePaywall: UIButton = {
        let button = UIButton(type: .system)
        button.setBackgroundImage(.closePaywall, for: .normal)
        button.alpha = 1
        return button
    }()
    
    private lazy var shadowImageView = UIImageView(image: .shadowPaywall)
    
    private lazy var policyButton = createMiniButtons(title: "Privacy Policy", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    
    private lazy var termsButton = createMiniButtons(title: "Terms of Use", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        layout.scrollDirection = .vertical
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "1")
        collection.delegate = self
        collection.dataSource = self    
        layout.minimumLineSpacing = 10
        return collection
    }()
    
    private lazy var progressView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .primary
        return view
    }()
    
    private lazy var activity: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .primary
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 16
        return view
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        loadProducts()
        setupUI()
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
        
        view.addSubview(closePaywall)
        closePaywall.addTarget(self, action: #selector(close), for: .touchUpInside)
        closePaywall.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(39)
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        shadowImageView.clipsToBounds = false
        view.addSubview(shadowImageView)
        view.bringSubviewToFront(shadowImageView) // Убедитесь, что тень на переднем плане
        shadowImageView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(3.3 / 5.0)
            make.height.lessThanOrEqualTo(600)
        }

        view.layoutIfNeeded()
        
        view.addSubview(policyButton)
        policyButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        policyButton.addTarget(self, action: #selector(openPolicy), for: .touchUpInside)
        
        view.addSubview(termsButton)
        termsButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        termsButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)
        
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.height.equalTo(254)
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(policyButton.snp.top).inset(-30)
        }
        
        view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.center.equalTo(collection.snp.center)
        }
        progressView.startAnimating()
        
        let additionalTokensLabel = UILabel()
        additionalTokensLabel.text = "Buy additional tokens"
        additionalTokensLabel.font = .appFont(.FootnoteRegular)
        additionalTokensLabel.textColor = .white.withAlphaComponent(0.6)
        view.addSubview(additionalTokensLabel)
        additionalTokensLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(collection.snp.top).inset(-30)
        }
        
        let mainlabel = UILabel()
        mainlabel.text = "Need more\ngenerations?"
        mainlabel.textColor = .white
        mainlabel.font = .appFont(.Title1Emphasized)
        mainlabel.textAlignment = .center
        mainlabel.numberOfLines = 2
        view.addSubview(mainlabel)
        mainlabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(additionalTokensLabel.snp.top).inset(-10)
        }
        
        
        let amountTokens: String = UserDefaults.standard.object(forKey: "amountTokens") as? String ?? "0"

        let myTokensLabel = UILabel()

        let mainText = "My tokens: "
        let mainAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.appFont(.CalloutRegular)
        ]

        let tokenText = amountTokens
        let tokenAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 255/255, green: 235/255, blue: 205/255, alpha: 1),
            .font: UIFont.appFont(.CalloutRegular)
        ]

        let attributedText = NSMutableAttributedString(string: mainText, attributes: mainAttributes)
        let attributedToken = NSAttributedString(string: tokenText, attributes: tokenAttributes)
        attributedText.append(attributedToken)

        myTokensLabel.attributedText = attributedText
        
        view.addSubview(myTokensLabel)
        myTokensLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(mainlabel.snp.top).inset(-10)
        }
        
        view.addSubview(activity)
        activity.snp.makeConstraints { make in
            make.height.width.equalTo(60)
            make.center.equalToSuperview()
        }
        activity.center = view.center
        
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
    
    private func loadProducts()  {
        model.tokenPurchaseManager.loadPaywalls {
            self.progressView.stopAnimating()
            self.collection.reloadData()
        }
    }
    
    
    @objc private func close() {
        self.dismiss(animated: true)
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
    
    private func returnSaveView(amount: String) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 255/255, green: 235/255, blue: 205/255, alpha: 1)
        view.layer.cornerRadius = 4
        
        let label = UILabel()
        label.font = .appFont(.Caption2Emphasized)
        label.textColor = .black
        
        switch amount {
        case "500":
            label.text = "SAVE 20%"
        case "1000":
            label.text = "SAVE 50%"
        case "2000":
            label.text = "SAVE 80%"
        default:
            label.text = "SAVE 0%"
        }
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        return view
    }
    
    private func createPurchase(selectedIndex: Int) {
        closePaywall.isEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.activity.startAnimating()
        }
        Task {
            do {
                let productToPurchase = model.tokenPurchaseManager.productsApphud[selectedIndex]
                model.tokenPurchaseManager.startPurchase(product: productToPurchase) { result in
                    if result == true {
                        
                        let parameters: [AppEvents.ParameterName: Any] = [
                            .init("product_id"): productToPurchase.skProduct?.productIdentifier ?? "no id", // Уникальный ID продукта
                            .init("price"): productToPurchase.skProduct?.price.doubleValue ?? 0.0, // Цена продукта
                            .init("currency"): productToPurchase.skProduct?.priceLocale.currencySymbol ?? "$" // Валюта
                        ]
                        AppEvents.shared.logEvent(AppEvents.Name("subscriptionPurchase_completed"), parameters: parameters)
                        
                       
                        
                        self.dismiss(animated: true)
                        self.closePaywall.isEnabled = true
                        UIView.animate(withDuration: 0.3) {
                            self.activity.alpha = 0
                        }
                    } else {
                        self.showErrorAlert()
                        UIView.animate(withDuration: 0.3) {
                            self.activity.alpha = 0
                        }
                    }
                }
            }
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "Payment failed. Write to us so we can help.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Close", style: .cancel)
        alert.addAction(okAction)
        
        let write = UIAlertAction(title: "Write to us", style: .default) { _ in
            self.contactUs()
        }
        alert.addAction(write)
        self.present(alert, animated: true)
    }
    
    @objc private func contactUs() {
        
        var versionText = ""
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionText = "App Version: \(version)"
        } else {
            versionText = "App Version: Unknown"
        }
        
        let email = "mcbayroxane@gmail.com"
        let subject = "Support Request" // Тема письма
        let body = "App ver: \(versionText), User id - \(userID)" // Текст письма

        // Создаем URL с добавлением темы и тела письма
        let emailURL = "mailto:\(email)?subject=\(subject)&body=\(body)"
        
        // Кодируем URL
        if let encodedURL = emailURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Не удалось открыть почтовое приложение.")
            }
        }
    }

}


extension TokenPaywallViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.tokenPurchaseManager.productsApphud.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .bgTeriary
        cell.layer.cornerRadius = 10
        
        let item = model.tokenPurchaseManager.productsApphud[indexPath.row]
        
      
        
        let amountLabel = UILabel()
        amountLabel.font = .appFont(.BodyEmphasized)
        amountLabel.textColor = .white
        amountLabel.text = item.skProduct?.localizedTitle ?? "100"
        cell.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }
        
        
        
        
        let arrowImageView = UIImageView(image: .rightArrow1.withRenderingMode(.alwaysTemplate))
        arrowImageView.tintColor = .white.withAlphaComponent(0.28)
        cell.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(15)
            make.width.equalTo(10)
        }
        
        let price = "\(item.skProduct?.price.doubleValue ?? 0.0)"
        let priceLabel = UILabel()
        priceLabel.font = .appFont(.BodyRegular)
        priceLabel.textColor = .white
        
        if let price = item.skProduct?.price.stringValue {
            priceLabel.text = (item.skProduct?.priceLocale.currencySymbol ?? "$") + price
        } else {
            priceLabel.text = ""
        }
        
        cell.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).inset(-10)
            make.centerY.equalToSuperview()
        }
        
        if item.skProduct?.localizedTitle != "100" {
            let viewSale = returnSaveView(amount: item.skProduct?.localizedTitle ?? "")
            cell.addSubview(viewSale)
            viewSale.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalTo(21)
                make.width.equalTo(66)
                make.right.equalTo(priceLabel.snp.left).inset(-10)
            }
        }
        
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        createPurchase(selectedIndex: indexPath.row)
        
    }
    
    
}
