//
//  SettingsViewController.swift
//  titEggs
//
//  Created by Владимир Кацап on 05.11.2024.
//

import UIKit
import StoreKit
import WebKit
import UserNotifications
import Combine
import OneSignalFramework

class SettingsViewController: UIViewController {
    
    var purchaseManager: PurchaseManager
    
    private let rightButton = PaywallButton()
    
    private let arrGeaders = ["Purchases", "Actions", "Support us", "Info & legal"]
    
    private lazy var cancellable = [AnyCancellable]()
    
    var model: MainModel
    
    
    
    private lazy var isNotification: Bool = {
        UserDefaults.standard.object(forKey: "isNotificaion") as? Bool ?? false
    }()
    
    init(purchaseManager: PurchaseManager, model: MainModel) {
        self.purchaseManager = purchaseManager
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var colelction: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.showsVerticalScrollIndicator = false
        layout.scrollDirection = .vertical
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "1")
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        return collection
    }()
    
    private lazy var cacheLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.4)
        label.font = .appFont(.BodyRegular)
        return label
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cacheLabel.text = getCache()
        checkManager()
        setupNavController()
        self.title = "Settings"
        colelction.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgPrimary
        setupNavController()
        setupUI()
        subscribe()
        colelction.reloadData()
        //openPaywallToken()
    }
    
    

    private func subscribe() {
        buyPublisher
            .sink { _ in
                self.checkManager()
            }
            .store(in: &cancellable)
    }
    
    private func checkManager() {
        
        print(purchaseManager.hasUnlockedPro, "- есть или нет покупок")
        colelction.reloadData()
        
        if purchaseManager.hasUnlockedPro {
            rightButton.alpha = 0
        } else {
            rightButton.alpha = 1
        }
    }
    
    private func setupNavController() {
        tabBarController?.title = "Settings"
        tabBarController?.navigationController?.navigationBar.prefersLargeTitles = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.appFont(.HeadlineRegular)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.appFont(.LargeTitleEmphasized)
        ]
        tabBarController?.navigationController?.navigationBar.standardAppearance = appearance
        tabBarController?.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        if purchaseManager.hasUnlockedPro == false {
            rightButton.addTarget(self, action: #selector(paywallButtonTapped), for: .touchUpInside)
            
            let barButtonItem = UIBarButtonItem(customView: rightButton)
            
            tabBarController?.navigationItem.rightBarButtonItem = barButtonItem
            rightButton.snp.makeConstraints { make in
                make.width.equalTo(80)
                make.height.equalTo(32)
            }
            rightButton.addTouchFeedback()
        }
        
        
    }
    
    @objc private func paywallButtonTapped() {
        if dynamicAppHud?.segment == "v2" {
            showNewPaywall()
        } else {
            self.present(CreateElements.openPaywall(manager: purchaseManager), animated: true)
        }
    }
    
    func showNewPaywall() {
        let paywallViewController = NewPaywallViewController(manager: purchaseManager)
        paywallViewController.modalPresentationStyle = .fullScreen
        paywallViewController.modalTransitionStyle = .coverVertical
        if #available(iOS 13.0, *) {
            paywallViewController.isModalInPresentation = true
        }
        self.present(paywallViewController, animated: true)
    }
    @objc private func restorePur() {
        purchaseManager.restorePurchase(escaping: { result in
            buyPublisher.send(1)
        })
    }
    
    
    private func setupUI() {
        view.addSubview(colelction)
        colelction.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
        }
    }
    
    private func createTopLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white.withAlphaComponent(0.8)
        label.font = .appFont(.FootnoteEmphasized)
        return label
    }
    
    private func createCellViews(cell: Int) -> UIView {
        
        let view = UIView()
        view.backgroundColor = .bgTeriary
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        switch cell {
        case 0:
            let viewOne = createSubView(text: "Upgrade plan", isArrow: true, image: .t1R1, isBotSeparator: true)
            let viewTwo = createSubView(text: "Restore purchases", isArrow: true, image: .t1R2, isBotSeparator: false)
            stackView.addArrangedSubview(viewOne)
            stackView.addArrangedSubview(viewTwo)
            viewOne.addTarget(self, action: #selector(paywallButtonTapped), for: .touchUpInside)
            viewTwo.addTarget(self, action: #selector(restorePur), for: .touchUpInside)
        case 1:
            let viewOne = createSubView(text: "Notifications", isArrow: false, image: .t2R1, isBotSeparator: true)
            let swithcer = UISwitch()
            swithcer.addTarget(self, action: #selector(enableNotify(sender:)), for: .valueChanged)
            swithcer.isOn = isNotification
            swithcer.onTintColor = UIColor(red: 39/255, green: 165/255, blue: 255/255, alpha: 1)
            viewOne.addSubview(swithcer)
            swithcer.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(15)
                make.height.equalTo(31)
                make.width.equalTo(51)
            }
            
            let viewTwo = createSubView(text: "Clear cache", isArrow: true, image: .t2R2, isBotSeparator: false)
            viewTwo.addSubview(cacheLabel)
            cacheLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(35)
            }
            viewTwo.addTarget(self, action: #selector(clearCache), for: .touchUpInside)
            stackView.addArrangedSubview(viewOne)
            stackView.addArrangedSubview(viewTwo)
        case 2:
            let viewOne = createSubView(text: "Rate app", isArrow: true, image: .t3R1, isBotSeparator: true)
            viewOne.addTarget(self, action: #selector(rateApp), for: .touchUpInside)
            let viewTwo = createSubView(text: "Share with friends", isArrow: true, image: .t3R2, isBotSeparator: false)
            viewTwo.addTarget(self, action: #selector(shareFriends), for: .touchUpInside)
            stackView.addArrangedSubview(viewOne)
            stackView.addArrangedSubview(viewTwo)
        case 3:
            let viewOne = createSubView(text: "Contact us", isArrow: true, image: .t4R1, isBotSeparator: true)
            viewOne.addTarget(self, action: #selector(contactUs), for: .touchUpInside)
            let viewTwo = createSubView(text: "Privacy Policy", isArrow: true, image: .t4R2, isBotSeparator: true)
            viewTwo.addTarget(self, action: #selector(privacyPol), for: .touchUpInside)
            let viewThree = createSubView(text: "Usage Policy", isArrow: true, image: .t4R3, isBotSeparator: false)
            viewThree.addTarget(self, action: #selector(usagePol), for: .touchUpInside)
            stackView.addArrangedSubview(viewOne)
            stackView.addArrangedSubview(viewTwo)
            stackView.addArrangedSubview(viewThree)
        default:
            print(4)
        }
        
        return view
    }
    
    private func getCache() -> String {
        let fileManager = FileManager.default
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let tempURL = fileManager.temporaryDirectory

        var totalSize: Int64 = 0

        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            for fileURL in cacheFiles {
                let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = fileAttributes[FileAttributeKey.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            let tempFiles = try fileManager.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: nil)
            for fileURL in tempFiles {
                let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = fileAttributes[FileAttributeKey.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        } catch {
            print("Ошибка при получении размера кэша: \(error.localizedDescription)")
        }

        let cacheSizeString: String
        if totalSize < 1024 {
            cacheSizeString = "\(totalSize) B"
        } else if totalSize < 1024 * 1024 {
            cacheSizeString = String(format: "%.1f KB", Double(totalSize) / 1024.0)
        } else {
            cacheSizeString = String(format: "%.1f MB", Double(totalSize) / (1024.0 * 1024.0))
        }

        return cacheSizeString
    }
    
    @objc private func clearCache() {
        
        let alertController = UIAlertController(title: "Clear cache?", message: "The cached files of your videos will be deleted from your phone's memory. But your download history will be retained.", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelButton)
        
        let clearButtpn = UIAlertAction(title: "Clear", style: .destructive) { _ in
            let fileManager = FileManager.default
            let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            do {
                let cacheFiles = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
                for fileURL in cacheFiles {
                    try fileManager.removeItem(at: fileURL)
                }
                self.checkManager()
                self.model.arr.removeAll()
                self.model.saveArr()
                self.model.publisherVideo.send(1)
                self.cacheLabel.text = self.getCache()
            } catch {
                self.cacheLabel.text = self.getCache()
                self.model.publisherVideo.send(1)
                self.checkManager()
                print("Ошибка при очистке кэша: \(error.localizedDescription)")
            }
        }
        alertController.addAction(clearButtpn)
        
        self.present(alertController, animated: true)
    }
    
    
    
    @objc private func contactUs() {
        
        var versionText = ""
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionText = "App Version: \(version)"
        } else {
            versionText = "App Version: Unknown"
        }
        
        let email = "mcbayroxane@gmail.com"
        let subject = "Support Request" // Тема письма
        let body = "App ver: \(versionText), User id - \(userID)" // Текст письма

        // Создаем URL с добавлением темы и тела письма
        let emailURL = "mailto:\(email)?subject=\(subject)&body=\(body)"
        
        // Кодируем URL
        if let encodedURL = emailURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Не удалось открыть почтовое приложение.")
            }
        }
    }

    private func requestNotificationAuthorization(completion: @escaping () -> Void) {
        OneSignal.Notifications.requestPermission({ accepted in
          print("User accepted notifications: \(accepted)")
            completion()
        }, fallbackToSettings: true)
    }


    @objc private func enableNotify(sender: UISwitch) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Проверяем текущее состояние разрешений на уведомления
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    if sender.isOn == true {
                        let alert = UIAlertController(title: "Allow notifications?",
                                                      message: "This app will be able to send you messages in your notification center",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
                    
                            self.requestNotificationAuthorization {
                                self.isNotification = true
                                sender.isOn = true
                                UserDefaults.standard.setValue(self.isNotification, forKey: "isNotificaion")
                            }
                            
                        })
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                            self.isNotification = false
                            sender.isOn = false
                            UserDefaults.standard.setValue(self.isNotification, forKey: "isNotificaion")
                        })
                        print( UserDefaults.standard.object(forKey: "isNotificaion") as? Bool ?? false)
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.isNotification = false
                        UserDefaults.standard.setValue(self.isNotification, forKey: "isNotificaion")
                        print( UserDefaults.standard.object(forKey: "isNotificaion") as? Bool ?? false)
                        sender.isOn = false
                    }
                }
                
            case .denied:
                // Уведомления были отключены, вы можете показать предупреждение
                print("Уведомления отключены. Пожалуйста, включите их в настройках.")
                DispatchQueue.main.async {
                    sender.isOn = false // Обновляем переключатель
                }
            case .notDetermined:
                // Запрашиваем разрешение на отправку уведомлений
                notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            sender.isOn = true // Если разрешение получено, устанавливаем переключатель в состояние "включено"
                            print("Уведомления включены.")
                        } else {
                            sender.isOn = false // Если разрешение не получено, устанавливаем переключатель в состояние "выключено"
                            print("Уведомления не были включены.")
                        }
                    }
                }
            case .provisional:
                // Временные уведомления разрешены
                print("Временные уведомления разрешены.")
            case .ephemeral:
                // Эфемерные уведомления разрешены
                print("Эфемерные уведомления разрешены.")
            @unknown default:
                break
            }
        }
    }
    
    private func checkAlert(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true) // Уведомления разрешены
            case .denied, .notDetermined:
                completion(false) // Уведомления не разрешены или статус еще не определен
            case .provisional:
                completion(true) // Временные уведомления разрешены (только для iOS 12 и выше)
            case .ephemeral:
                completion(true) // Эфемерные уведомления разрешены (только для iOS 14 и выше)
            @unknown default:
                completion(false) // Обработка других, неизвестных статусов
            }
        }
    }
    
    //supp
    @objc private func rateApp() {
        if #available(iOS 14, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                DispatchQueue.main.async {
                    AppStore.requestReview(in: scene)
                }
            }
        } else {
            let appID = "ID"
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(6737900240)?action=write-review") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    
    @objc private func shareFriends() {
        guard let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String else {
            return
        }
        let appID = "6737900240"
        let appURL = "https://apps.apple.com/app/id\(appID)"
        let shareText = "\(appName)\n\(appURL)"
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // Настройка для iPad
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // Центр экрана
            popoverController.permittedArrowDirections = [] // Убираем стрелку поповера
        }
        
        present(activityViewController, animated: true, completion: nil)
    }

    
    @objc private func privacyPol() {
        let webVC = WebViewController()
        webVC.urlString = "https://www.termsfeed.com/live/84172d38-c955-48c8-bad2-34beb03770c9"
        present(webVC, animated: true, completion: nil)
    }

    @objc private func usagePol() {
        let webVC = WebViewController()
        webVC.urlString = "https://www.termsfeed.com/live/b1287ca9-a8f5-49d4-ab0c-82f9f8fec119"
        present(webVC, animated: true, completion: nil)
    }
    
    private func createSubView(text: String, isArrow: Bool, image: UIImage, isBotSeparator: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.addTouchFeedback()
        button.backgroundColor = .clear
        
        let imageView = UIImageView(image: image)
        button.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.equalTo(36)
            make.left.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }
        
        let labelText = UILabel()
        labelText.text = text
        labelText.textColor = .white
        labelText.font = .appFont(.BodyRegular)
        
        button.addSubview(labelText)
        labelText.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right)
            make.centerY.equalToSuperview()
        }
        
        if isArrow {
            let arrowImageView = UIImageView(image: .rightArrow)
            button.addSubview(arrowImageView)
            arrowImageView.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.height.equalTo(44)
                make.width.equalTo(24)
                make.centerY.equalToSuperview()
            }
        }
        
        if isBotSeparator {
            let viewSep = UIView()
            viewSep.backgroundColor = .white
            button.addSubview(viewSep)
            viewSep.snp.makeConstraints { make in
                make.height.equalTo(0.33)
                make.bottom.equalToSuperview()
                make.right.equalToSuperview()
                make.left.equalTo(labelText.snp.left)
            }
        }
        return button
    }
    
}


extension SettingsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "1", for: indexPath)
        cell.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .bgPrimary
        
        
        
        if (indexPath.row != 0)  {
            let topLabel = createTopLabel(text: arrGeaders[indexPath.row - 1])
            cell.addSubview(topLabel)
            topLabel.snp.makeConstraints { make in
                make.left.top.equalToSuperview()
            }
            
            let viewCell = createCellViews(cell: indexPath.row - 1)
            cell.addSubview(viewCell)
            viewCell.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(topLabel.snp.bottom).inset(-5)
                make.height.equalTo(indexPath.row == 4 ? 132 : 88)
               
            }
            //cell.backgroundColor = .red
            
            if (indexPath.row == 4)  {
                let versionlabel = UILabel()
                versionlabel.textColor = .white.withAlphaComponent(0.6)
                versionlabel.font = .appFont(.FootnoteRegular)
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    versionlabel.text = "App Version: \(version)"
                } else {
                    versionlabel.text = "App Version: Unknown"
                }
                
                cell.addSubview(versionlabel)
                versionlabel.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(20)
                }
            }
        }
        
        if indexPath.row == 0  {
            let view = UIView()
            view.backgroundColor = .bgTeriary
            view.layer.cornerRadius = 10
            cell.addSubview(view)
            view.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.centerY.equalToSuperview().offset(-10)
                make.height.equalTo(42)
            }
            
            let label = UILabel()
            label.text = "Tokens to generate:"
            label.textColor = .white
            label.font = .appFont(.CalloutEmphasized)
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(15)
                make.centerY.equalToSuperview()
            }
            
            let numberTokens: String = UserDefaults.standard.object(forKey: "alltokens") as? String ?? "100"
            
            
            let labelAllToken = UILabel()
            labelAllToken.font = .appFont(.BodyEmphasized)
            labelAllToken.textColor = .white
            labelAllToken.text = " / " + (purchaseManager.hasUnlockedPro ? numberTokens : "0")
            view.addSubview(labelAllToken)
            labelAllToken.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(15)
            }
            
            let amountTokens: String = UserDefaults.standard.object(forKey: "amountTokens") as? String ?? "0"
            
            
            let amountLabel = UILabel()
            amountLabel.textColor = .white.withAlphaComponent(0.4)
            amountLabel.font = .appFont(.CalloutRegular)
            amountLabel.text = amountTokens
            view.addSubview(amountLabel)
            amountLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalTo(labelAllToken.snp.left)
            } 
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0  {
            return CGSize(width: collectionView.bounds.width, height: 60)
        } else {
            return CGSize(width: collectionView.bounds.width, height: indexPath.row == 4 ? 206 : 112)
        }
        
    }
}


class WebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var urlString: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView

        if let urlString = urlString, let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
}
