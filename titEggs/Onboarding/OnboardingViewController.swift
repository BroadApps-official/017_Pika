//
//  OnboardingViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 04.11.2024.
//

import UIKit
import StoreKit

class OnboardingViewController: UIViewController {
    
    private let arr: [OnbData] = [OnbData(image: "futureVideo", topText: "Pick a photo &\nblow it up", botText: "Create unreal videos"),
    OnbData(image: "futureVideo", topText: "Turn everything\nyou see", botText: "Quick and easy"),
    OnbData(image: "futureVideo", topText: "Take a photo &\nCake-ify it", botText: "Surprise your friends"),
    OnbData(image: "futureVideo", topText: "Rate our app in\nthe AppStore", botText: "Lots of satisfied users")]
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPage = 0
        control.numberOfPages = arr.count
        control.currentPageIndicatorTintColor = .white
        control.isUserInteractionEnabled = false
        return control
    }()
    
    private lazy var nextButton = CreateElements.createPrimaryButton(title: "Continue")
    
    private lazy var tap = 0
    
    private lazy var collection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collection.isPagingEnabled = true
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "1")
        collection.isUserInteractionEnabled = false
        collection.delegate = self
        collection.dataSource = self
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupUI()
    }
    

    private func setupUI() {
        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        
        view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(goNext), for: .touchUpInside)
        nextButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(pageControl.snp.top).inset(-10)
            make.height.equalTo(48)
        }
        
        view.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).inset(-10)
        }
        
    }
    
    @objc private func goNext() {
        let nextIndex = min(pageControl.currentPage + 1, arr.count - 1)
        let indexPath = IndexPath(item: nextIndex, section: 0)
        collection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        pageControl.currentPage = nextIndex
        tap += 1
        
        
        switch tap {
        case 4:
            requestReview()
        case 5:
            self.navigationController?.setViewControllers([NotifyOnbViewController()], animated: true)
        default:
            return
        }
        
        
        
    }
    
    private func requestReview() {
        if #available(iOS 14.0, *) {
            if let windowScene = self.view.window?.windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    
}


extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
    
        let item = arr[indexPath.row]
        
        let imageView = UIImageView(image: UIImage(named: item.image))
        imageView.contentMode = .scaleAspectFill
        cell.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(3.0/2.0)
        }
        
        let shadowImageView = UIImageView(image: .onbShadow)
        shadowImageView.contentMode = .scaleAspectFill
        cell.addSubview(shadowImageView)
        shadowImageView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(cell.snp.height).multipliedBy(1.0 / 3.0)
        }
        
        
        let botLabel = UILabel()
        botLabel.textColor = .white.withAlphaComponent(0.6)
        botLabel.text = item.botText
        botLabel.font = .appFont(.BodyRegular)
        shadowImageView.addSubview(botLabel)
        botLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(10)
        }
        
        let topLabel = UILabel()
        topLabel.numberOfLines = 2
        topLabel.text = item.topText
        topLabel.textAlignment = .center
        topLabel.font = .appFont(.LargeTitleEmphasized)
        topLabel.textColor = .white
        shadowImageView.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(botLabel.snp.top)
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = pageIndex
    }
}
