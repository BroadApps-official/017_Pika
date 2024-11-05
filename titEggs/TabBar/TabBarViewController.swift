//
//  TabBarViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import SnapKit

class TabBarViewController: UITabBarController {
    
    private var manager: PurchaseManager
    
    init(manager: PurchaseManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateBuy()
    }
    
    private func setupUI() {
        tabBar.unselectedItemTintColor = .white.withAlphaComponent(0.4)
        tabBar.tintColor = .primary
        tabBar.backgroundColor = .bgChromeMaterialbar
        tabBar.isTranslucent = false
        tabBar.barTintColor = UIColor.bgChromeMaterialbar
        
        let separatorView = UIView()
        separatorView.backgroundColor = .white.withAlphaComponent(0.24)
        tabBar.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.height.equalTo(0.33)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        let createVCNo = CreateViewController(purchaseManager: manager)
        let settingsVCNo = SettingsViewController(purchaseManager: manager)
        
        let createVc = createVC(VC: createVCNo, image: .create.resize(targetSize: CGSize(width: 32, height: 32)), title: "Create")
        let videosVc = createVC(VC: UIViewController(), image: .myVideos.resize(targetSize: CGSize(width: 32, height: 32)), title: "My Videos")
        let settingsVc = createVC(VC: settingsVCNo, image: .settings.resize(targetSize: CGSize(width: 20, height: 20)), title: "Settings")
        
        createVCNo.purchaseManager = manager
        settingsVCNo.purchaseManager = manager
        
        viewControllers = [createVc, videosVc, settingsVc]
    }
   
    private func createVC(VC: UIViewController, image: UIImage, title: String) -> UIViewController {
        let tapItem = UITabBarItem(title: title, image: image, tag: 0)
        VC.tabBarItem = tapItem
        return UINavigationController(rootViewController: VC)
    }
    
    private func updateBuy() {
        Task {
            await manager.updatePurchasedProducts()
        }
    }


}
