//
//  CreateViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import Combine

class CreateViewController: UIViewController {
    
    private let rightButton = PaywallButton()
    
    var purchaseManager: PurchaseManager
    
    private lazy var cancellable = [AnyCancellable]()
    
    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkManager()
    }
    
    private func checkManager() {
        
        print(purchaseManager.hasUnlockedPro, "- есть или нет покупок")
        
        if purchaseManager.hasUnlockedPro {
            rightButton.alpha = 0
        } else {
            rightButton.alpha = 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribe()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupNavController()
    }
    private func subscribe() {
        buyPublisher
            .sink { _ in
                print(123456789)
                self.checkManager()
            }
            .store(in: &cancellable)
    }
    
    private func setupNavController() {
        self.title = "Create"
        navigationController?.navigationBar.prefersLargeTitles = true
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
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        if purchaseManager.hasUnlockedPro == false {
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
    
    @objc private func paywallButtonTapped() {
        self.present(CreateElements.openPaywall(manager: purchaseManager), animated: true)
    }
    
    
    
    
    
    private func setupUI() {
        let label = UILabel()
        label.text = "Create"
        label.font = UIFont.appFont(.LargeTitleEmphasized)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        
    }
    
}
