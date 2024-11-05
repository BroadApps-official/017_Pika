//
//  PaywallViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import StoreKit
import WebKit

class PaywallViewController: UIViewController {
    
    private var timer: Timer?
    
    private let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Unreal videos with\nPRO"
        label.font = .appFont(.Title1Emphasized)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var policyButton = createMiniButtons(title: "Privacy Policy", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    private lazy var termsButton = createMiniButtons(title: "Terms of Use", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption2Regular), isACancelAnytime: false)
    private lazy var restoreButton = createMiniButtons(title: "Restore Purchases", color: .white.withAlphaComponent(0.6), font: .appFont(.Caption1Regular), isACancelAnytime: false)
    
    
    private lazy var continueButton = CreateElements.createPrimaryButton(title: "Continue")
    private lazy var cancelAnytimeButton = createMiniButtons(title: "Cancel Anytime", color: .white.withAlphaComponent(0.4), font: .appFont(.Caption1Regular), isACancelAnytime: true)
    
    private lazy var annualButton = createSubscribeButtons(type: true, selected: true)
    private lazy var weeklyButton = createSubscribeButtons(type: false, selected: false)
    private lazy var selectedSubscribe = true  // тру -1 кнопка ; фолс - вторая
    private lazy var buttonsTopStackView = UIStackView(arrangedSubviews: [annualButton, weeklyButton])
    
    private lazy var progressView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .primary
        return view
    }()
    
    
    private lazy var closePaywall: UIButton = {
        let button = UIButton(type: .system)
        button.setBackgroundImage(.closePaywall, for: .normal)
        button.alpha = 0
        return button
    }()
    
    //MARK: -Store
    private let manager:PurchaseManager
    private lazy var products: [Product] = []
    
    
    init(manager: PurchaseManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        someMethod()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupTimer()
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
        do {
            try await manager.loadProducts()
            self.products = manager.products
            self.buttonsTopStackView.alpha = 1
            self.selectPlan(sender: self.annualButton)
            self.progressView.alpha = 0
        } catch {
            print("Ошибка при загрузке продуктов: \(error)")
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
    
    
    private func setupUI() {
        let imageView = UIImageView(image: .paywallVideo)
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(4.0/5.0)
        }
        
        let shadowImageView = UIImageView(image: .shadowPaywall)
        view.addSubview(shadowImageView)
        shadowImageView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            
            make.height.equalTo(view.snp.height).multipliedBy(4.1 / 5.0).priority(.low)
            make.height.lessThanOrEqualTo(600)
        }
        
        policyButton.addTarget(self, action: #selector(openPolicy), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restore), for: .touchUpInside)
        
        let stackViewBot = UIStackView(arrangedSubviews: [policyButton, restoreButton, termsButton])
        stackViewBot.backgroundColor = .clear
        stackViewBot.axis = .horizontal
        stackViewBot.distribution = .equalSpacing
        stackViewBot.spacing = 10
        view.addSubview(stackViewBot)
        stackViewBot.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        
        view.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(48)
            make.bottom.equalTo(stackViewBot.snp.top).inset(-10)
        }
        continueButton.addTarget(self, action: #selector(createPurchase), for: .touchUpInside)
        
        cancelAnytimeButton.isUserInteractionEnabled = false
        view.addSubview(cancelAnytimeButton)
        cancelAnytimeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).inset(-10)
        }
        
        
        view.addSubview(progressView)
        progressView.startAnimating()
        progressView.snp.makeConstraints { make in
            make.height.equalTo(120)
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(cancelAnytimeButton.snp.top).inset(-20)
        }
        
        
        
        buttonsTopStackView.alpha = 0
        buttonsTopStackView.axis = .vertical
        buttonsTopStackView.distribution = .fillEqually
        buttonsTopStackView.spacing = 8
        view.addSubview(buttonsTopStackView)
        buttonsTopStackView.snp.makeConstraints { make in
            make.height.equalTo(120)
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(cancelAnytimeButton.snp.top).inset(-20)
        }
        
        let topStackView = UIStackView(arrangedSubviews: [createTextGalc(text: "Full Access"), createTextGalc(text: "Share unique videos"), createTextGalc(text: "Quick generation")])
        topStackView.backgroundColor = .clear
        topStackView.axis = .vertical
        topStackView.distribution = .fillEqually
        topStackView.alignment = .leading
        topStackView.spacing = 1
        view.addSubview(topStackView)
        topStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(progressView.snp.top).inset(-20)
            make.height.equalTo(100)
            make.width.equalTo(174)
        }
        
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(topStackView.snp.top).inset(-10)
        }
        
        view.addSubview(closePaywall)
        closePaywall.addTarget(self, action: #selector(close), for: .touchUpInside)
        closePaywall.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(39)
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }
    
    @objc private func createPurchase() {
        Task {
            do {
                let productToPurchase = selectedSubscribe ? products.first : products.last
                guard let product = productToPurchase else { return }
                try await manager.purchase(product)
                self.dismiss(animated: true)
            } catch {
                print("Ошибка при покупке: \(error)")
            }
        }
    }



    
    private func createStackView() {
        
    }
    
    @objc private func close() {
        self.dismiss(animated: true)
    }
    
    @objc private func openPolicy() {
        let webVC = WebViewController()
        webVC.urlString = "PRIVA"
        present(webVC, animated: true, completion: nil)
    }
    
    @objc private func openTerms() {
        let webVC = WebViewController()
        webVC.urlString = "TERMS"
        present(webVC, animated: true, completion: nil)
    }
    
    @objc private func restore() {
        manager.restoreArrPurchase()
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
    
    private func createSubscribeButtons(type: Bool, selected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 10
        button.tag = type ? 1 : 0
        
        let dotImageView = UIImageView(image: selected ? .selectedSub.withRenderingMode(.alwaysTemplate) : .unselectedSub.withRenderingMode(.alwaysTemplate))
        dotImageView.tintColor = selected ? .primary : .white.withAlphaComponent(0.28)
        button.addSubview(dotImageView)
        dotImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(32)
        }
        
        button.layer.borderColor = selected ? UIColor.primary.cgColor : UIColor.clear.cgColor
        button.layer.borderWidth = selected ? 1 : 0
        
        let typeLabel = UILabel()
        typeLabel.text = type ? products.first?.displayName : products.last?.displayName
        typeLabel.textColor = .white
        typeLabel.font = .appFont(.BodyRegular)
        button.addSubview(typeLabel)
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(dotImageView.snp.right).inset(-5)
            if type {
                make.top.equalToSuperview().inset(10)
            } else {
                make.centerY.equalToSuperview()
            }
        }
        
        let saleLabel = UILabel()
        saleLabel.font = .appFont(.Caption1Regular)
        saleLabel.textColor = .white.withAlphaComponent(0.4)
        saleLabel.text = "$0.87 per week"
        
        if type {
            button.addSubview(saleLabel)
            saleLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(10)
                make.left.equalTo(dotImageView.snp.right).inset(-5)
            }
        }
        
        let countlabel = UILabel()
        countlabel.font = .appFont(.BodyEmphasized)
        countlabel.textColor = .white
        countlabel.text = type ? products.first?.displayPrice : products.last?.displayPrice
        button.addSubview(countlabel)
        countlabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.top.equalToSuperview().inset(10)
        }
        
        let textLabel = UILabel()
        textLabel.textColor = .white.withAlphaComponent(0.6)
        textLabel.font = .appFont(.Caption1Regular)
        textLabel.text = type ? "per year" : "per week"
        button.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(10)
        }
        
        if type {
            let view = createSaleView()
            button.addSubview(view)
            view.snp.makeConstraints { make in
                make.centerY.equalTo(countlabel)
                make.height.equalTo(21)
                make.width.equalTo(66)
                make.right.equalTo(countlabel.snp.left).inset(-5)
            }
        }
        
        
        button.addTarget(self, action: #selector(selectPlan(sender:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside])
        return button
    }
    
    @objc private func selectPlan(sender: UIButton) {
        buttonsTopStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if sender.tag == 1 {
            selectedSubscribe = true
            annualButton = createSubscribeButtons(type: true, selected: true)
            weeklyButton = createSubscribeButtons(type: false, selected: false)
        } else {
            selectedSubscribe = false
            weeklyButton = createSubscribeButtons(type: false, selected: true)
            annualButton = createSubscribeButtons(type: true, selected: false)
        }
        
        buttonsTopStackView.addArrangedSubview(annualButton)
        buttonsTopStackView.addArrangedSubview(weeklyButton)
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        sender.alpha = 0.7
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        sender.alpha = 1
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
        
        return view
    }
    
}

