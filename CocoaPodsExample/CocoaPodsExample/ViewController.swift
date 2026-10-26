//
//  ViewController.swift
//  CocoaPodsExample
//
//  Checkout-IOS integration: build the configuration from the saved settings, start the checkout
//  and log every callback. The Settings screen edits the same inputs as the Tap web demo.
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

    /// Shows what the next checkout will do: charge or authorize, and for how much.
    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    /// Edited in the Settings screen and persisted in UserDefaults; reloaded whenever this screen appears.
    private var settings = CheckoutSettings.load()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tap Checkout"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(openSettings))

        view.addSubview(checkoutButton)
        view.addSubview(summaryLabel)
        view.addSubview(callbacksTextView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            checkoutButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 40),
            checkoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkoutButton.widthAnchor.constraint(equalToConstant: 200),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50),

            summaryLabel.topAnchor.constraint(equalTo: checkoutButton.bottomAnchor, constant: 12),
            summaryLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            summaryLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            callbacksTextView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 20),
            callbacksTextView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            callbacksTextView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            callbacksTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings = CheckoutSettings.load()
        let mode = settings.mode == "authorize" ? "Authorize (\(settings.authorizeType))" : "Charge"
        summaryLabel.text = "\(mode) · \(settings.totalAmount.formatted) \(settings.selectedCurrency)"
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func startCheckout() {
        guard settings.hasPublicKey else {
            let alert = UIAlertController(
                title: "Public key missing",
                message: "Set your Tap sandbox public key in Keys.swift (Keys.publicKey), or enter it in Settings > SDK Configuration > Public Key.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        // The SDK takes a plain dictionary; `makeConfiguration()` builds it like the Tap web demo does.
        CheckoutSDK().start(configurations: settings.makeConfiguration(), delegate: self)
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

private extension Double {
    /// 0.1 -> "0.1", 10.0 -> "10" (no trailing ".0").
    var formatted: String {
        let text = String(self)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
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
