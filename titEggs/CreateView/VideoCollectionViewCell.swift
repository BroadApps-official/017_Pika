//
//  VideoCollectionViewCell.swift
//  titEggs
//
//  Created by Владимир Кацап on 08.11.2024.
//

import UIKit
import AVFoundation
import SnapKit

class VideoCollectionViewCell: UICollectionViewCell {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    // Контейнер для видео
    let videoContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        return view
    }()
    
    // Метка
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .appFont(.BodyRegular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Добавляем контейнер видео в ячейку
        addSubview(videoContainerView)
        videoContainerView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview().inset(10)
            make.height.equalTo(128)
        }
        
        // Добавляем метку в ячейку
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with videoURL: URL, title: String) {
        titleLabel.text = title
        
        // Удаляем предыдущий слой, если он существует
        playerLayer?.removeFromSuperlayer()
        
        // Создаем AVPlayer для видео
        player = AVPlayer(url: videoURL)
        player?.isMuted = true

        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        videoContainerView.layer.addSublayer(playerLayer!)

        layoutIfNeeded()
        playerLayer?.frame = videoContainerView.bounds

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player?.play()
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
    }
}

