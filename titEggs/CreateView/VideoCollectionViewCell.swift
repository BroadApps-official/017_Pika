//
//  VideoCollectionViewCell.swift
//  titEggs
//
//  Created by Владимир Кацап on 08.11.2024.
//

import UIKit
import AVFoundation
import SnapKit
import GSPlayer

class VideoCollectionViewCell: UICollectionViewCell {
    private var player = VideoPlayerView()
    

    
    // Метка
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .appFont(.BodyRegular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        player.clipsToBounds = true
        player.layer.cornerRadius = 10
        
        // Добавляем контейнер видео в ячейку
        addSubview(player)
        player.snp.makeConstraints { make in
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

    func configure(with videoURL: URL?, title: String) {
        titleLabel.text = title
        

        if videoURL != nil {
            player.play(for: videoURL!)
            player.isMuted = true
        }

    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        player.pause(reason: .userInteraction)
        player.removeFromSuperview()
    }
}

