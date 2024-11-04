//
//  CreateViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit

class CreateViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        
        for family in UIFont.familyNames {
            print("\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }

        setupUI()
    }
    

    private func setupUI() {
        let label = UILabel()
        label.text = "Create"
        label.font = UIFont.appFont(.LargeTitleEmphasized)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
//        let vc = CreateElements.openPaywall()
//        self.present(vc, animated: true)
    }

}
