//
//  CustomLikeViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 05.11.2024.
//

import UIKit

class CustomLikeViewController: UIViewController {
    
    private lazy var closeVCButton: UIButton = {
        let button = UIButton(type: .system)
        button.setBackgroundImage(.closePaywall, for: .normal)
        button.tintColor = .primary
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
    }
    

    private func setupUI() {
        view.addSubview(closeVCButton)
        closeVCButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(39)
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        closeVCButton.addTarget(self, action: #selector(closeVC), for: .touchUpInside)
        
        let likeImageView = UIImageView(image: .customLike)
        view.addSubview(likeImageView)
        likeImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-100)
            make.height.equalTo(222)
            make.width.equalTo(268)
        }
        
        let topLabel = UILabel()
        topLabel.text = "Do you like our app?"
        topLabel.textColor = .white
        topLabel.font = .appFont(.Title3Emphasized)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(likeImageView.snp.bottom)
        }
        
        let supLabel = UILabel()
        supLabel.text = "Please rate our app so we can improve it for\nyou and make it even cooler"
        supLabel.numberOfLines = 2
        supLabel.textAlignment = .center
        supLabel.font = .appFont(.FootnoteRegular)
        supLabel.textColor = .white.withAlphaComponent(0.8)
        view.addSubview(supLabel)
        supLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topLabel.snp.bottom).inset(-5)
        }
        
        let noButton = createButtons(type: false)
        let yesButton = createButtons(type: true)
        noButton.addTarget(self, action: #selector(closeVC), for: .touchUpInside)
        yesButton.addTarget(self, action: #selector(write), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [yesButton, noButton])
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.left.right.equalToSuperview().inset(15)
            make.top.equalTo(supLabel.snp.bottom).inset(-25)
        }
        
    }
    
    private func createButtons(type: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.addTouchFeedback()
        button.layer.cornerRadius = 10
        
        button.setTitle(type ? "😊 Yes!" : "😔 No", for: .normal)
        button.titleLabel?.font = .appFont(.BodyRegular)
        button.backgroundColor = type ? .primary : .primary.withAlphaComponent(0.12)
        button.setTitleColor(type ? .black : .primary, for: .normal)
        return button
    }
    
    @objc private func closeVC() {
        self.dismiss(animated: true)
    }
    
    @objc private func write() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6737900240?action=write-review") else { //как пример - 6737510164
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Unable to open App Store")
        }
        UserDefaults.standard.setValue("Ok", forKey: "rewiew")
    }


}
