//
//  TabBarViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import SnapKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        tabBar.unselectedItemTintColor = .white.withAlphaComponent(0.4)
        tabBar.tintColor = .primary
        tabBar.backgroundColor = .bgChromeMaterialbar
        
        let separatorView = UIView()
        separatorView.backgroundColor = .white.withAlphaComponent(0.24)
        tabBar.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.height.equalTo(0.33)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        let createVc = createVC(VC: CreateViewController(), image: .create.resize(targetSize: CGSize(width: 32, height: 32)), title: "Create")
        let videosVc = createVC(VC: UIViewController(), image: .myVideos.resize(targetSize: CGSize(width: 32, height: 32)), title: "My Videos")
        let settingsVc = createVC(VC: UIViewController(), image: .settings.resize(targetSize: CGSize(width: 20, height: 20)), title: "Settings")
        
        viewControllers = [createVc, videosVc, settingsVc]
    }
   
    private func createVC(VC: UIViewController, image: UIImage, title: String) -> UIViewController {
        let tapItem = UITabBarItem(title: title, image: image, tag: 0)
        VC.tabBarItem = tapItem
        return UINavigationController(rootViewController: VC)
    }

}
