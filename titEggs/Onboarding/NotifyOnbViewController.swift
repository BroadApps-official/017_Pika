//
//  NotifyOnbViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import UserNotifications
import OneSignalFramework

class NotifyOnbViewController: UIViewController {
    
    var paywall: PurchaseManager
    
    init(paywall: PurchaseManager) {
        self.paywall = paywall
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    private let laterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.setTitle("Maybe later", for: .normal)
        button.titleLabel?.font = .appFont(.SubheadlineRegular)
        button.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
        return button
    }()
    
    private let turnOnButton = CreateElements.createPrimaryButton(title: "Turn on notifications")
    
    private let subTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Allow notifications"
        label.font = .appFont(.BodyRegular)
        label.textColor = .white.withAlphaComponent(0.6)
        return label
    }()
    
    private let mainTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Don't miss new\ntrends"
        label.numberOfLines = 2
        label.font = .appFont(.LargeTitleEmphasized)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
    }
    
    
    private func setupUI() {
        
        let imageView = UIImageView(image: .requestAlert)
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(3.0/2.0)
        }
        
        let shadowImageView = UIImageView(image: .shadowPaywall)
        view.addSubview(shadowImageView)
        shadowImageView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(1.3 / 3.0)
        }
        
        view.addSubview(laterButton)
        laterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        laterButton.addTarget(self, action: #selector(hideVc), for: .touchUpInside)
        
        view.addSubview(turnOnButton)
        turnOnButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(48)
            make.bottom.equalTo(laterButton.snp.top).inset(-10)
        }
        turnOnButton.addTarget(self, action: #selector(requestAlert), for: .touchUpInside)
        
        view.addSubview(subTextLabel)
        subTextLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(turnOnButton.snp.top).inset(-30)
        }
        
        view.addSubview(mainTextLabel)
        mainTextLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(subTextLabel.snp.top)
        }
        
    }
    
    @objc private func requestAlert() {
        requestNotificationAuthorization {
            self.hideVc()
            UserDefaults.standard.setValue(true, forKey: "isNotificaion")
        }
    }
    
    @objc private func hideVc() {
        self.navigationController?.setViewControllers([TabBarViewController(manager: self.paywall)], animated: true)
        paywallButtonTapped()
        UserDefaults.standard.setValue(1, forKey: "onb")
    }
    
    @objc private func paywallButtonTapped() {
        if dynamicAppHud?.segment == "v1" {
            showNewPaywall()
        } else {
            self.present(CreateElements.openPaywall(manager: paywall), animated: true)
        }
      //  showNewPaywall()
    }
    
    func showNewPaywall() {
        let paywallViewController = NewPaywallViewController(manager: paywall)
        paywallViewController.modalPresentationStyle = .fullScreen
        paywallViewController.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            paywallViewController.isModalInPresentation = true
        }
        self.present(paywallViewController, animated: true)
    }
    
    private func requestNotificationAuthorization(completion: @escaping () -> Void) {
        OneSignal.Notifications.requestPermission({ accepted in
          print("User accepted notifications: \(accepted)")
            completion()
        }, fallbackToSettings: true)
    }
    
}
