//
//  PaywallButton.swift
//  titEggs
//
//  Created by Владимир Кацап on 05.11.2024.
//

import UIKit

class PaywallButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .primary
        layer.cornerRadius = 8
        self.setImage(.crown.resize(targetSize: CGSize(width: 32, height: 32)), for: .normal)
        self.setTitle("PRO", for: .normal)
        self.setTitleColor(.black, for: .normal)
        self.titleLabel?.font = .appFont(.SubheadlineEmphasized)
        
    }

}
