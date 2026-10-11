//
//  ViewController.swift
//  CheckoutExample
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import UIKit
import Checkout_IOS
import SnapKit

class ViewController: UIViewController, CheckoutSettingsViewControllerDelegate {
    private lazy var checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Checkout", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(startCheckout), for: .touchUpInside)
        return button
    }()
    
    private lazy var configButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Options", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(editParams), for: .touchUpInside)
        return button
    }()
    
    private lazy var callbacksLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0 // Allow multiple lines
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.text = "Callbacks will appear here..."
        // Add padding
        label.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return label
    }()
    
    private lazy var callbacksScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    
    private var callbackMessages: [String] = []
    private let maxCallbacksToShow = 10
    
    var configurations:[String:Any] = [
        "hashString": "",
        "language": "en",
        "themeMode": "light",
        "supportedPaymentMethods": "ALL",
        "paymentType": "ALL",
        "selectedCurrency": "KWD",
        "supportedCurrencies": "ALL",
        "supportedPaymentTypes": [],
        "supportedRegions": [],
        "supportedSchemes": [],
        "supportedCountries": [],
        "gateway": [
            "publicKey": "pk_test_ohzQrUWRnTkCLD1cqMeudyjX",
            "merchantId": ""
        ],
        "customer": [
            "firstName": "Android",
            "lastName": "Test",
            "email": "example@gmail.com",
            "phone": [
                "countryCode": "965",
                "number": "55567890"
            ]
        ],
        "transaction": [
            "mode": "charge",
            "charge": [
                "saveCard": true,
                "auto": [
                    "type": "VOID",
                    "time": 100
                ],
                "redirect": [
                    "url": "https://demo.staging.tap.company/v2/sdk/checkout"
                ],
                "threeDSecure": true,
                "subscription": [
                    "type": "SCHEDULED",
                    "amount_variability": "FIXED",
                    "txn_count": 0
                ],
                "airline": [
                    "reference": [
                        "booking": ""
                    ]
                ]
            ]
        ],
        "amount": "5",
        "order": [
            "id": "",
            "currency": "KWD",
            "amount": "5",
            "items": [
                [
                    "amount": "5",
                    "currency": "KWD",
                    "name": "Item Title 1",
                    "quantity": 1,
                    "description": "item description 1"
                ]
            ]
        ],
        "cardOptions": [
            "showBrands": true,
            "showLoadingState": false,
            "collectHolderName": true,
            "preLoadCardName": "",
            "cardNameEditable": true,
            "cardFundingSource": "all",
            "saveCardOption": "all",
            "forceLtr": false,
            "alternativeCardInputs": [
                "cardScanner": true,
                "cardNFC": true
            ]
        ],
        "isApplePayAvailableOnClient": true,
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(checkoutButton)
        view.addSubview(configButton)
        view.addSubview(callbacksScrollView)
        callbacksScrollView.addSubview(callbacksLabel)

        checkoutButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
        
        configButton.snp.makeConstraints { make in
            make.centerX.equalTo(checkoutButton.snp.centerX)
            make.top.equalTo(checkoutButton.snp.bottom).offset(10)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
        
        callbacksScrollView.snp.makeConstraints { make in
            make.top.equalTo(configButton.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
        
        callbacksLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            make.width.equalTo(callbacksScrollView.snp.width).offset(-16)
        }
    }
    
    private func addCallbackMessage(_ message: String) {
        // Add timestamp to the message
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] \(message)"
        
        // Add the new message to the array
        callbackMessages.insert(formattedMessage, at: 0)
        
        // Limit the number of messages to show
        if callbackMessages.count > maxCallbacksToShow {
            callbackMessages = Array(callbackMessages.prefix(maxCallbacksToShow))
        }
        
        // Update the label text
        callbacksLabel.text = callbackMessages.joined(separator: "\n\n")
        
        // Ensure the scroll view updates its content size
        callbacksLabel.sizeToFit()
        callbacksScrollView.contentSize = callbacksLabel.bounds.size
        
        // Scroll to the top to show the latest message
        callbacksScrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    @objc private func editParams() {
        let configCtrl = CheckoutSettingsViewController()
        configCtrl.config = configurations
        configCtrl.delegate = self
        self.navigationController?.pushViewController(configCtrl, animated: true)
    }

    
    @objc private func startCheckout() {
        // Example configurations - replace with your actual configuration
        CheckoutSDK().start(configurations: configurations, delegate: self)
    }
    
    func checkoutSettingsViewControllerDidSave(_ config: [String : Any]) {
        configurations = config
    }
}

// MARK: - CheckoutSDKDelegate
extension ViewController: CheckoutSDKDelegate {
    func onClose() {
        addCallbackMessage("onClose: Checkout was closed")
    }
    
    func onReady() {
        addCallbackMessage("onReady: Checkout is ready")
    }
    
    func onSuccess(data: String) {
        addCallbackMessage("onSuccess: \(data)")
    }
    
    func onChargeCreated(data: String) {
        addCallbackMessage("onChargeCreated: \(data)")
    }
    
    func onError(data: String) {
        addCallbackMessage("onError: \(data)")
    }
    
    var controller: UIViewController {
        return self
    }
}
