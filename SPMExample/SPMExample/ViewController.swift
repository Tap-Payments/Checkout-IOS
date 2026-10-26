//
//  ViewController.swift
//  SPMExample
//
//  Minimal Checkout-IOS integration: start the checkout and log every callback.
//

import UIKit
import Checkout_IOS

class ViewController: UIViewController {
    private lazy var checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Checkout", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startCheckout), for: .touchUpInside)
        return button
    }()

    private lazy var callbacksTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textColor = .darkGray
        textView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        textView.layer.cornerRadius = 8
        textView.text = "Callbacks will appear here..."
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private var callbackMessages: [String] = []

    // Sandbox configuration; replace the public key with your own.
    private let configurations: [String: Any] = [
        "hashString": "",
        "language": "en",
        "themeMode": "light",
        "supportedPaymentMethods": "ALL",
        "paymentType": "ALL",
        "selectedCurrency": "KWD",
        "supportedCurrencies": "ALL",
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
                "redirect": [
                    "url": "https://demo.staging.tap.company/v2/sdk/checkout"
                ],
                "threeDSecure": true
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
            "collectHolderName": true,
            "cardFundingSource": "all",
            "saveCardOption": "all",
            "alternativeCardInputs": [
                "cardScanner": true
            ]
        ],
        "isApplePayAvailableOnClient": true,
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(checkoutButton)
        view.addSubview(callbacksTextView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            checkoutButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 40),
            checkoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkoutButton.widthAnchor.constraint(equalToConstant: 200),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50),

            callbacksTextView.topAnchor.constraint(equalTo: checkoutButton.bottomAnchor, constant: 30),
            callbacksTextView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            callbacksTextView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            callbacksTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
        ])
    }

    @objc private func startCheckout() {
        CheckoutSDK().start(configurations: configurations, delegate: self)
    }

    private func addCallbackMessage(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        callbackMessages.insert("[\(formatter.string(from: Date()))] \(message)", at: 0)
        DispatchQueue.main.async {
            self.callbacksTextView.text = self.callbackMessages.joined(separator: "\n\n")
        }
    }
}

// MARK: - CheckoutSDKDelegate
extension ViewController: CheckoutSDKDelegate {
    var controller: UIViewController {
        return self
    }

    func onReady() {
        addCallbackMessage("onReady: Checkout is ready")
    }

    func onChargeCreated(data: String) {
        addCallbackMessage("onChargeCreated: \(data)")
    }

    func onSuccess(data: String) {
        addCallbackMessage("onSuccess: \(data)")
    }

    func onError(data: String) {
        addCallbackMessage("onError: \(data)")
    }

    func onClose() {
        addCallbackMessage("onClose: Checkout was closed")
    }
}
