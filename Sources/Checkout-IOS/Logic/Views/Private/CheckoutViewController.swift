//
//  CheckoutViewController.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import UIKit
import SharedDataModels_iOS
import CoreTelephony
import SwiftEntryKit
import WebKit
import AVFoundation

class CheckoutViewController: UIViewController {
    
    // MARK: - Properties
    internal let configurations: [String: Any]
    internal let results: CheckoutSDKResults
    internal var webView: WKWebView?
    internal var detectedIP: String = ""
    
    // MARK: - Static Properties
    internal static let cdnUrl: String = "https://tap-sdks.b-cdn.net/mobile/checkout/base_url.json"
    internal static var tabCheckoutConfigUrl: String = "https://mw-sdk.tap.company/v2/"
    internal static var tabCheckoutUrl: String = "https://mw-sdk.tap.company/v2/"
    internal static var sandboxKey: String = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8AX++RtxPZFtns4XzXFlDIxPB
h0umN4qRXZaKDIlb6a3MknaB7psJWmf2l+e4Cfh9b5tey/+rZqpQ065eXTZfGCAu
BLt+fYLQBhLfjRpk8S6hlIzc1Kdjg65uqzMwcTd0p7I4KLwHk1I0oXzuEu53fU1L
SZhWp4Mnd6wjVgXAsQIDAQAB
-----END PUBLIC KEY-----
"""
    internal static var productionKey: String = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8AX++RtxPZFtns4XzXFlDIxPB
h0umN4qRXZaKDIlb6a3MknaB7psJWmf2l+e4Cfh9b5tey/+rZqpQ065eXTZfGCAu
BLt+fYLQBhLfjRpk8S6hlIzc1Kdjg65uqzMwcTd0p7I4KLwHk1I0oXzuEu53fU1L
SZhWp4Mnd6wjVgXAsQIDAQAB
-----END PUBLIC KEY-----
"""
    
    // MARK: - Computed Properties
    private var isSandbox: Bool {
        let gatewayConfig = configurations["gateway"] as? [String:Any]
        let key = gatewayConfig?["publicKey"] as? String ?? ""
        return key.contains("test")
    }
    
    internal var headersEncryptionPublicKey: String {
        return isSandbox ? CheckoutViewController.sandboxKey : CheckoutViewController.productionKey
    }
    
    internal var languageCode: String {
        let language =  configurations["language"] as? String ?? "en"
        if language == "ar" {
            return "ar"
        } else {
            return "en"
        }
    }
    
    // MARK: - Initialization
    init(configurations: [String: Any], results: CheckoutSDKResults) {
        self.configurations = configurations
        self.results = results
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupConstraints()
        getIP()
        getCDNURL()
    }
}

// MARK: - UI Setup
extension CheckoutViewController {
    
    func setupWebView() {
        // Creates needed configuration for the web view
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        // Let us make sure it is of a clear background and opaque, not to interfere with the merchant's app background
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor.clear
        webView?.scrollView.backgroundColor = UIColor.clear
        webView?.scrollView.bounces = false
        webView?.isHidden = false
        // Let us add it to the view
        self.view.backgroundColor = UIColor.clear
        if #available(iOS 11.0, *) {
            webView?.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        self.view.addSubview(webView!)
        
    }
    
    func setupConstraints() {
        guard let webView = self.webView else {
            return
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}


// MARK: - WKNavigationDelegate
extension CheckoutViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("navigationAction: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var action: WKNavigationActionPolicy?
        
        defer {
            decisionHandler(action ?? .allow)
        }
        
        guard let url = navigationAction.request.url else { return }
        
        if url.absoluteString.hasPrefix("tapcheckoutsdk") {
            print("navigationAction", url.absoluteString)
            action = .cancel
        } else {
            print("navigationAction", url.absoluteString)
        }
        
        switch url.absoluteString {
        case _ where url.absoluteString.contains("onReady"):
            results.onReady()
        case _ where url.absoluteString.contains("onError"):
            handleError(data: tap_extractDataFromUrl(url.absoluteURL))
        case _ where url.absoluteString.contains("onSuccess"):
            handleSuccess(data: tap_extractDataFromUrl(url.absoluteURL))
        case _ where url.absoluteString.contains("onClose"):
            handleClose()
        case _ where url.absoluteString.contains("onRedirectUrl"):
            handleRedirection(data: tap_extractDataFromUrl(url.absoluteURL))
        case _ where url.absoluteString.contains("onScannerClick"):
            handleScanCard()
            break
        case _ where url.absoluteString.contains("onChargeCreated"):
            handleOnChargeCreated(data: tap_extractDataFromUrl(url.absoluteURL))
        default:
            break
        }
    }
}

// MARK: - Callback Handlers
extension CheckoutViewController {
    
    func closeViewController(callback: @escaping (() -> Void)) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                callback()
            }
        }
    }
    
    func handleClose() {
        self.closeViewController { [weak self] in
            guard let self = self else { return }
            self.results.onClose()
        }
    }
    
    func handleOnChargeCreated(data: String) {
        self.results.onChargeCreated(data: data)
    }
    
    func handleSuccess(data: String) {
        self.closeViewController{ [weak self] in
            guard let self = self else { return }
            self.results.onSuccess(data: data)
        }
    }
    
    func handleError(data: String) {
        self.closeViewController{ [weak self] in
            guard let self = self else { return }
            self.results.onError(data: data)
        }
    }
    
    
    
    func handleRedirection(data: String) {
        // let us make sure we have the data we need to start such a process
        guard let redirectionData: RedirectionData = try? RedirectionData(data),
              let _: String = redirectionData.url,
              let _: String = redirectionData.redirectionUrl?.url else {
            // This means, there is such an error from the integration with web sdk
            handleError(data: "Failed to start redirect process")
            return
        }
        
        // This means we are ok to start the authentication process
        let redirectView: RedirectionView = .init(frame: .zero)
        // Set to web view the needed urls
        redirectView.redirectionData = redirectionData
        // Set the selected card locale for correct semantic rendering
        redirectView.selectedLocale = languageCode
        // Set to web view what should it when the process is canceled by the user
        redirectView.redirectionViewClosed = {
            SwiftEntryKit.dismiss()
            self.webView?.evaluateJavaScript("window.returnBack()")
        }
        // Hide or show the powered by tap based on coming parameter
        redirectView.poweredByTapView.isHidden = !(redirectionData.powered ?? true)
        // Set to web view what should it when the process is completed by the user
        redirectView.redirectionReached = { chargeId in
            SwiftEntryKit.dismiss {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.handleSuccess(data: chargeId)
                }
            }
        }
        // Set to web view what should it do when the content is loaded in the background
        redirectView.idleForWhile = {
            DispatchQueue.main.async {
                SwiftEntryKit.display(entry: redirectView, using: redirectView.swiftEntryAttributes())
            }
        }
        // Tell it to start rendering 3ds content in background
        redirectView.startLoading()
    }
    
    /// Starts the scanning process if all requirements are met
    internal func handleScanCard() {
        let scannerController:TapScannerViewController = .init()
        scannerController.delegate = self
        //scannerController.modalPresentationStyle = .overCurrentContext
        // Second grant the authorization to use the camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
                DispatchQueue.main.async {
                    self.present(scannerController, animated: true)
                }
            }else {
                self.handleError(data: "{\"error\":\"The user didn't approve accessing the camera.\"}")
            }
        }
    }
}

extension CheckoutViewController: TapScannerViewControllerDelegate {
    func cardScanned(with card: TapCard, and scanner: TapScannerViewController) {
        scanner.dismiss(animated: true) {
            self.handleScanner(with: card)
        }
    }
    
    internal func handleScanner(with scannedCard:TapCard) {
        webView?.evaluateJavaScript("window.fillCardInputs({cardNumber: '\(scannedCard.tapCardNumber ?? "")',expiryDate: '\(scannedCard.tapCardExpiryMonth ?? "")/\(scannedCard.tapCardExpiryYear ?? "")',cvv: '\(scannedCard.tapCardCVV ?? "")',cardHolderName: '\(scannedCard.tapCardName ?? "")'})")
    }
    
}


