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
    var publisher: PassthroughSubject<Bool, Never>
    var video: Video?
    
    var uuidVideo = ""
    
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
    
    init(model: MainModel, image: Data, index:  Int, publisher: PassthroughSubject<Bool, Never>, video: Video?) {
        self.model = model
        self.image = image
        self.index = index
        self.publisher = publisher
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
        setupTimer()
        openLike()
        addImageInarr()
        supscribe()
    }
    
    private func supscribe() {
        model.errorPublisher
            .sink { (error, id) in
                self.alertError(id: id)
            }
            .store(in: &cancellabel)
        
        model.videoDownloadedPublisher
            .sink { id in
                self.videoIsDownload(id: id)
            }
            .store(in: &cancellabel)
    }
    
    private func alertError(id: String) {
        if id == uuidVideo {
            DispatchQueue.main.async {
                self.openAlert()
            }
        }
    }
    
    private func videoIsDownload(id: String) {
        print(id, uuidVideo, "ID VIDEO AND UUID")

        if id == uuidVideo {
            DispatchQueue.main.async { [self] in
                publisher.send(true)
                self.dismiss(animated: true)
                timer?.invalidate()
                print("ВИДЕО ФУЛЛ ЗАГРУЖЕНО")
            }
        }
    }
    
   
    
    private func addImageInarr() {
        if model.workItems.count >= 2 {
            DispatchQueue.main.async {
                self.limitAlert()
            }
        } else {
            
            var videoLoad = video
            
            if video == nil {
                videoLoad = Video(image: image, effectID: model.effectsArr[index].id, video: nil, generationID: nil, resultURL: nil, dataGenerate: self.getTodayFormattedData(), effectName: model.effectsArr[index].effect, status: nil)
            } else {
                videoLoad = video
            }
            
        
            uuidVideo = "\(videoLoad!.id)"
            
            model.createVideo(video: videoLoad!, escaping: { result in
                if result == false {
                    DispatchQueue.main.async {
                        self.openAlert()
                    }
                }
            })
        }
    }
    
    func getTodayFormattedData() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let today = Date()
        return dateFormatter.string(from: today)
    }
    
    private func limitAlert() {
        let alert = UIAlertController(title: "You have reached the simultaneous generation limit ", message: "You cannot generate more than 2 videos at the same time", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Got it", style: .cancel) { _ in
            self.closeVC()
        }
        alert.addAction(cancelButton)
        self.present(alert, animated: true)
    }
    
    private func openAlert() {
        let alert = UIAlertController(title: "Video generation error", message: "Something went wrong or the server is not responding. Try again or do it later.", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.closeVC()
        }
        alert.addAction(cancelButton)
        
        let repeatButton = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.count = 0.0
            self.addImageInarr()
        }
        alert.addAction(repeatButton)
        self.present(alert, animated: true)
    }

    private func setupUI() {
        let closeGenButton = UIButton(type: .system)
        closeGenButton.setBackgroundImage(.closeBut, for: .normal)
        view.addSubview(closeGenButton)
        closeGenButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(76)
            make.left.equalToSuperview()
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
        publisher.send(false)
        timer?.invalidate()
        timer = nil
    }
    
}




