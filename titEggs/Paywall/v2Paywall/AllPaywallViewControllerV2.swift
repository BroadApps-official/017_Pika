//
//  AllPaywallViewController.swift
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

class AllPaywallViewControllerV2: UIViewController {
    
    private let manager:PurchaseManager
    private lazy var products: [ApphudProduct] = []
    
    init(manager: PurchaseManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var selectedSubscribe = 0
    var topStackView: UIStackView?
    
    private let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Unlock Pika Premium"
        label.font = .appFont(.Title1Emphasized)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var policyButton = createMiniButtons(title: "Privacy Policy", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    private lazy var termsButton = createMiniButtons(title: "Terms of Use", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    private lazy var restoreButton = createMiniButtons(title: "Restore Purchases", color: .white.withAlphaComponent(0.6), font: .appFont(.Caption1Regular), isACancelAnytime: false)
    
    private lazy var activity: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .primary
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var numberGenButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.backgroundColor = .white.withAlphaComponent(0.08)
        button.titleLabel?.font = .appFont(.Caption1Emphasized)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.setTitle("100", for: .normal)
        return button
    }()
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "1")
        layout.scrollDirection = .vertical
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        layout.minimumLineSpacing = 4
        return collection
    }()
    
    private lazy var cancelAnytimeButton = createMiniButtons(title: "Cancel Anytime", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption1Regular), isACancelAnytime: true)
    
    private lazy var progressView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .primary
        return view
    }()
    
    private lazy var continueButton = CreateElements.createPrimaryButton(title: "Continue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
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

        // Когда продуктов достаточно, выполняем нужный код
        self.products = manager.productsApphud
        self.collection.reloadData()
        self.selectPlan(index: 0)
        self.progressView.alpha = 0
        self.continueButton.isEnabled = true
        collection.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(cancelAnytimeButton.snp.top).inset(-20)
            make.height.equalTo(products.count * 60)
        }
        UIView.animate(withDuration: 0.3) {
            let time = self.returnType(product: self.products[0])
            
           
                switch time {
                case "per week":
                    self.numberGenButton.setTitle("10", for: .normal)
                case "per year":
                    self.numberGenButton.setTitle("100", for: .normal)
                case "per month":
                    self.numberGenButton.setTitle("10", for: .normal)
                default:
                    self.numberGenButton.setTitle("0", for: .normal)
                }
                self.topStackView?.addArrangedSubview(self.createTextGalc(text: "Number of generations:"))
            
            self.view.layoutIfNeeded()
        }
    }

    
    private func setupUI() {
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
        
        view.addSubview(continueButton)
        continueButton.addTarget(self, action: #selector(createPurchase), for: .touchUpInside)
        continueButton.isEnabled = false
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(48)
            make.bottom.equalTo(restoreButton.snp.top).inset(-15)
        }
        
        cancelAnytimeButton.isUserInteractionEnabled = false
        view.addSubview(cancelAnytimeButton)
        cancelAnytimeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).inset(-15)
        }
        
        view.addSubview(progressView)
        progressView.startAnimating()
        progressView.snp.makeConstraints { make in
            make.height.equalTo(120)
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(cancelAnytimeButton.snp.top).inset(-20)
        }
        
        
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(cancelAnytimeButton.snp.top).inset(-20)
            make.height.equalTo(products.count == 0 ? 120 : products.count * 60)
        }
        
        
        view.addSubview(activity)
        activity.stopAnimating()
        activity.snp.makeConstraints { make in
            make.height.width.equalTo(60)
            make.center.equalToSuperview()
        }
        activity.center = view.center
        
        topStackView = UIStackView(arrangedSubviews: [createTextGalc(text: "Full Access"), createTextGalc(text: "Share unique videos"), createTextGalc(text: "Quick generation")])
        
        topStackView?.backgroundColor = .clear
        topStackView?.axis = .vertical
        topStackView?.distribution = .fillEqually
        topStackView?.alignment = .leading
        topStackView?.spacing = 1
        view.addSubview(topStackView!)
        topStackView?.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-40)
            make.bottom.equalTo(collection.snp.top).inset(-20)
            make.height.equalTo(134)
            make.width.equalTo(174)
        }
        
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(topStackView!.snp.top).inset(-10)
        }
    }
    
    @objc private func createPurchase() {
        UIView.animate(withDuration: 0.3) {
            self.activity.startAnimating()
        }
        Task {
            do {
                let productToPurchase = products[selectedSubscribe]
                manager.startPurchase(produst: productToPurchase) { result in
                    if result == true {
                        
                        let parameters: [AppEvents.ParameterName: Any] = [
                            .init("product_id"): productToPurchase.skProduct?.productIdentifier ?? "no id", // Уникальный ID продукта
                            .init("price"): productToPurchase.skProduct?.price.doubleValue ?? 0.0, // Цена продукта
                            .init("currency"): productToPurchase.skProduct?.priceLocale.currencySymbol ?? "$" // Валюта
                        ]
                        AppEvents.shared.logEvent(AppEvents.Name("subscriptionPurchase_completed"), parameters: parameters)
                        if self.numberGenButton.titleLabel?.text == "10" {
                            UserDefaults.standard.setValue("100", forKey: "amountTokens")
                            UserDefaults.standard.setValue("100", forKey: "alltokens")
                        } else {
                            UserDefaults.standard.setValue("1000", forKey: "amountTokens")
                            UserDefaults.standard.setValue("1000", forKey: "alltokens")
                        }
                        self.dismiss(animated: true)
                    }
                    
                    UIView.animate(withDuration: 0.3) {
                        self.activity.stopAnimating()
                    }
                    
                }
            }
        }
    }
    
    @objc private func selectPlan(index: Int) {
       selectedSubscribe = index
        
        collection.reloadData()
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
    
    private func returnType(product: ApphudProduct) -> String {
        guard let subscriptionPeriod = product.skProduct?.subscriptionPeriod else {
            return ""
        }

        switch subscriptionPeriod.unit {
        case .day: return "per week"
        case .week: return "per week"
        case .month: return "per month"
        case .year: return "per year"
        @unknown default: return "Unknown"
        }
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
    
    @objc private func restore() {
        UIView.animate(withDuration: 0.3) {
            self.activity.startAnimating()
        }
        
        
        manager.restorePurchases { result in
            switch result {
            case .success(let isRestored):
                if isRestored {
                    self.showAlert(title: "Success", message: "Your purchases have been restored.")
                    self.activity.stopAnimating()
                } else {
                    self.showAlert(title: "Attention", message: "No purchases found. Write to us if this is not the case.")
                    self.activity.stopAnimating()
                }
            case .failure(let error):
                self.showAlert(title: "Error", message: "An error occurred while restoring purchases: \(error.localizedDescription)")
                self.activity.stopAnimating()
            }
        }
    }
    
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    private func createTextGalc(text: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let imageView = UIImageView(image: .galc)
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(32)
            make.left.equalToSuperview()
        }
        
        let label = UILabel()
        label.text = text
        label.font = .appFont(.SubheadlineRegular)
        label.textColor = .white.withAlphaComponent(0.8)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).inset(-5)
            make.centerY.equalTo(imageView)
        }
        
        if text == "Number of generations:" {
            view.addSubview(numberGenButton)
            numberGenButton.snp.makeConstraints { make in
                make.height.equalTo(24)
                make.centerY.equalTo(label)
                make.left.equalTo(label.snp.right).inset(-10)
            }
        }
        
        return view
    }
    
    private func returnName(product: ApphudProduct) -> String {
        guard let subscriptionPeriod = product.skProduct?.subscriptionPeriod else {
            return ""
        }

        switch subscriptionPeriod.unit {
        case .day: return "Weekly"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        @unknown default: return "Unknown"
        }
    }
    
    private func createSaleView() -> UIView {
        let view = UIView()
        view.backgroundColor = .primary
        view.layer.cornerRadius = 4
        let label = UILabel()
        label.text = "SAVE 80%"
        label.font = .appFont(.Caption2Emphasized)
        label.textColor = .black
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return view
    }

}

extension AllPaywallViewControllerV2: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
        
        cell.backgroundColor = .white.withAlphaComponent(0.08)
        cell.layer.cornerRadius = 10
        
        cell.layer.borderColor = indexPath.row == selectedSubscribe ? UIColor.primary.cgColor : UIColor.clear.cgColor
        cell.layer.borderWidth = 1
        
        let dotImageView = UIImageView(image: indexPath.row == selectedSubscribe ? .selectedSub.withRenderingMode(.alwaysTemplate) : .unselectedSub.withRenderingMode(.alwaysTemplate))
        dotImageView.tintColor = indexPath.row == selectedSubscribe ? .primary : .white.withAlphaComponent(0.28)
        cell.addSubview(dotImageView)
        dotImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(32)
        }
        
        let znak = products[indexPath.row].skProduct?.priceLocale.currencySymbol
        
        let typeLabel = UILabel()
        typeLabel.text = returnName(product: products[indexPath.row])
        
       
        
        typeLabel.textColor = .white
        typeLabel.font = .appFont(.BodyRegular)
        cell.addSubview(typeLabel)
        
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(dotImageView.snp.right).inset(-5)
            if typeLabel.text == "Yearly" {
                make.top.equalToSuperview().inset(10)
            } else {
                make.centerY.equalToSuperview()
            }
        }
    
        let saleLabel = UILabel()
        saleLabel.font = .appFont(.Caption1Regular)
        saleLabel.textColor = .white.withAlphaComponent(0.6)
        saleLabel.text = "$0.87 per week"
        
        if typeLabel.text == "Yearly" {
            cell.addSubview(saleLabel)
            saleLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(10)
                make.left.equalTo(dotImageView.snp.right).inset(-5)
            }
        }
        
        let countlabel = UILabel()
        countlabel.font = .appFont(.BodyEmphasized)
        countlabel.textColor = .white
        
        
        
        
        if let price = products[indexPath.row].skProduct?.price.stringValue {
            countlabel.text = "\((znak ?? "$") + price)/\(returnType(product: products[indexPath.row]))"
            saleLabel.text = (znak ?? "$") + price
        } else {
            countlabel.text = ""
        }
        
        
        cell.addSubview(countlabel)
        countlabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }
        
//        if typeLabel.text != "Yearly" {
//            let textLabel = UILabel()
//            textLabel.textColor = .white.withAlphaComponent(0.6)
//            textLabel.font = .appFont(.Caption1Regular)
//            textLabel.text = returnType(product: products[indexPath.row])
//            cell.addSubview(textLabel)
//            textLabel.snp.makeConstraints { make in
//                make.right.equalToSuperview().inset(15)
//                make.bottom.equalToSuperview().inset(10)
//            }
//        }
        
        
        if typeLabel.text == "Yearly" {
            countlabel.text = "🔥 $0.87/per week 🔥"
            countlabel.font = .appFont(.FootnoteEmphasized)
            countlabel.snp.remakeConstraints { make in
                make.right.bottom.equalToSuperview().inset(10)
            }
            
            
            let view = createSaleView()
            cell.addSubview(view)
            view.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(5)
                make.height.equalTo(21)
                make.width.equalTo(66)
                make.right.equalToSuperview().inset(10)
            }
        } else {
            countlabel.textColor = .white.withAlphaComponent(0.6)
            countlabel.font = .appFont(.FootnoteRegular)
        }
        
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedSubscribe = indexPath.row
        collectionView.reloadData()
        
        let time = returnType(product: products[indexPath.row])
        
        UIView.animate(withDuration: 0.3) {
            switch time {
            case "per week":
                self.numberGenButton.setTitle("10", for: .normal)
            case "per year":
                self.numberGenButton.setTitle("100", for: .normal)
            case "per month":
                self.numberGenButton.setTitle("10", for: .normal)
            default:
                self.numberGenButton.setTitle("0", for: .normal)
            }
        }
        
        
    }
}
