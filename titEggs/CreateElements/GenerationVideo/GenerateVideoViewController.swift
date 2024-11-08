//
//  GenerateVideoViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 07.11.2024.
//

import UIKit
import Lottie
import Combine

class GenerateVideoViewController: UIViewController {
    
    var model: MainModel
    var image: Data
    var index: Int
    
    //other
    private var timer: Timer?
    private var count = 0.0
    private lazy var cancellabel = [AnyCancellable]()
    
    private var progressView: UIProgressView = {
        let prog = UIProgressView(progressViewStyle: .bar)
        prog.layer.cornerRadius = 3
        prog.clipsToBounds = true
        prog.trackTintColor = .white.withAlphaComponent(0.14)
        prog.progressTintColor = UIColor.primary
        return prog
    }()
    
    init(model: MainModel, image: Data, index:  Int) {
        self.model = model
        self.image = image
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        addImageInarr()
        setupUI()
        setupTimer()
        openLike()
    }
    
    
    
    private func addImageInarr() {
        model.createVideo(image: image, idEffect: index, escaping: { result in
            if !result {
                self.openAlert()
            }
        })
    }
    
    private func openAlert() {
        let alert = UIAlertController(title: "Video generation error", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelButton)
        
        let repeatButton = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.addImageInarr()
        }
        alert.addAction(repeatButton)
        self.present(alert, animated: true)
    }

    private func setupUI() {
        let closeGenButton = UIButton(type: .system)
        closeGenButton.setBackgroundImage(.closeGen, for: .normal)
        view.addSubview(closeGenButton)
        closeGenButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(39)
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        closeGenButton.addTarget(self, action: #selector(closeVC), for: .touchUpInside)
        
        let lottieView = LottieAnimationView(name: "Generate")
        lottieView.loopMode = .loop
        lottieView.play()
        view.addSubview(lottieView)
        lottieView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(280)
            make.width.equalTo(263)
            make.centerY.equalToSuperview().offset(-120)
        }
        
        let topLabel = UILabel()
        topLabel.text = "Video Generation..."
        topLabel.textColor = .white
        topLabel.font = .appFont(.Title3Emphasized)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.top.equalTo(lottieView.snp.bottom)
            make.centerX.equalToSuperview()
        }
        
        let botLabel = UILabel()
        botLabel.text = "Generation usually takes about a minute"
        botLabel.textColor = .white.withAlphaComponent(0.8)
        botLabel.font = .appFont(.FootnoteRegular)
        view.addSubview(botLabel)
        botLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topLabel.snp.bottom).inset(-3)
        }
        
        progressView.setProgress(0, animated: false)
        view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.height.equalTo(6)
            make.width.equalTo(160)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(60)
        }
    }
    
    private func setupTimer() {
        count = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.count += 0.0005 
            if self.count < 1 {
                UIView.animate(withDuration: 0.1) {
                    self.progressView.setProgress(Float(self.count), animated: true)
                }
            } else {
                self.progressView.setProgress(1.0, animated: true)
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    private func openLike() {
        if UserDefaults.standard.object(forKey: "rewiew") == nil {
            var like: Int = UserDefaults.standard.integer(forKey: "likes")
            like += 1
            if like % 3 == 0 {
                self.openCustomLike()
            }
            UserDefaults.standard.setValue(like, forKey: "likes")
            print(like, "like")
        }
    }
    
    
    
    private func openCustomLike() {
        let customViewController = CustomLikeViewController()
        customViewController.modalPresentationStyle = .fullScreen
        customViewController.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            customViewController.isModalInPresentation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.present(customViewController, animated: true, completion: nil)
        }
        
    }

    
    deinit {
        self.index = 00
        self.image = Data()
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func closeVC() {
        self.dismiss(animated: true)
        timer?.invalidate()
        timer = nil
    }
    
}
