//
//  CreateElements.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import Foundation
import UIKit

class CreateElements {
    
    static func createPrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .primary
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = 10
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .appFont(.BodyRegular)
        return button
    }

    
    
    static func openPaywall(manager: PurchaseManager) -> UIViewController {
        let paywallViewController = PaywallViewController(manager: manager)
        paywallViewController.modalPresentationStyle = .fullScreen
        paywallViewController.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            paywallViewController.isModalInPresentation = true
        }
        return paywallViewController
    }
    
}
