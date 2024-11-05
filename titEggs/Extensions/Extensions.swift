//
//  Extensions.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import Foundation
import UIKit


extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}



enum AppFont {
    case LargeTitleRegular
    case LargeTitleEmphasized
    
    case Title1Regular
    case Title1Emphasized
    
    case Title2Regular
    case Title2Emphasized
    
    case Title3Regular
    case Title3Emphasized
    
    case HeadlineRegular
    
    case BodyRegular
    case BodyEmphasized
    
    case CalloutRegular
    case CalloutEmphasized
    
    case SubheadlineRegular
    case SubheadlineEmphasized
    
    case FootnoteRegular
    case FootnoteEmphasized
    
    case Caption1Regular
    case Caption1Emphasized
    
    case Caption2Regular
    case Caption2Emphasized
    
    var font: UIFont {
        switch self {
        case .LargeTitleRegular:
            return .systemFont(ofSize: 34, weight: .regular, width: .expanded)
        case .LargeTitleEmphasized:
            return .systemFont(ofSize: 34, weight: .bold, width: .expanded)
        case .Title1Regular:
            return .systemFont(ofSize: 28, weight: .regular, width: .expanded)
        case .Title1Emphasized:
            return .systemFont(ofSize: 28, weight: .bold, width: .expanded)
        case .Title2Regular:
            return .systemFont(ofSize: 22, weight: .regular, width: .expanded)
        case .Title2Emphasized:
            return .systemFont(ofSize: 22, weight: .bold, width: .expanded)
        case .Title3Regular:
            return .systemFont(ofSize: 20, weight: .regular, width: .expanded)
        case .Title3Emphasized:
            return .systemFont(ofSize: 20, weight: .bold, width: .expanded)
        case .HeadlineRegular:
            return .systemFont(ofSize: 17, weight: .semibold, width: .expanded)
        case .BodyRegular:
            return UIFont(name: "SFProText-Regular", size: 17)!
        case .BodyEmphasized:
            return UIFont(name: "SFProText-Semibold", size: 17)!
        case .CalloutRegular:
            return UIFont(name: "SFProText-Regular", size: 16)!
        case .CalloutEmphasized:
            return UIFont(name: "SFProText-Semibold", size: 16)!
        case .SubheadlineRegular:
            return UIFont(name: "SFProText-Regular", size: 15)!
        case .SubheadlineEmphasized:
            return UIFont(name: "SFProText-Semibold", size: 15)!
        case .FootnoteRegular:
            return UIFont(name: "SFProText-Regular", size: 13)!
        case .FootnoteEmphasized:
            return UIFont(name: "SFProText-Semibold", size: 13)!
        case .Caption1Regular:
            return UIFont(name: "SFProText-Regular", size: 12)!
        case .Caption1Emphasized:
            return UIFont(name: "SFProText-Medium", size: 12)!
        case .Caption2Regular:
            return UIFont(name: "SFProText-Regular", size: 11)!
        case .Caption2Emphasized:
            return UIFont(name: "SFProText-Semibold", size: 11)!
        }
    }
}

extension UIFont {
    static func appFont(_ font: AppFont) -> UIFont {
        return font.font
    }
}

extension UIViewController {
    func hideNavigationBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func showNavigationBar() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}


extension UIButton {
    func addTouchFeedback() {
        self.addTarget(self, action: #selector(didTouchDown), for: .touchDown)
        self.addTarget(self, action: #selector(didTouchUp), for: .touchUpInside)
        self.addTarget(self, action: #selector(didTouchUp), for: .touchUpOutside)
    }

    @objc private func didTouchDown() {
        self.alpha = 0.7
    }

    @objc private func didTouchUp() {
        self.alpha = 1.0
    }
}
