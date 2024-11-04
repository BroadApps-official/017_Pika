//
//  LoadViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit

class LoadViewController: UIViewController {
    
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        setTimer()
    }
    

    private func setupUI() {
        let imageView = UIImageView(image: .appIcon)
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.width.equalTo(160)
        }
        
        let progressIndicator = UIActivityIndicatorView(style: .large)
        progressIndicator.color = .white
        progressIndicator.startAnimating()
        view.addSubview(progressIndicator)
        progressIndicator.snp.makeConstraints { make in
            make.height.width.equalTo(30)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(30)
            make.centerX.equalToSuperview()
        }
        
    }
    
    private func setTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in //7
            if UserDefaults.standard.object(forKey: "onb") != nil {
                self.navigationController?.setViewControllers([TabBarViewController()], animated: true)
            } else {
                self.navigationController?.setViewControllers([OnboardingViewController()], animated: true)
            }
        })
    }
    
    
}
