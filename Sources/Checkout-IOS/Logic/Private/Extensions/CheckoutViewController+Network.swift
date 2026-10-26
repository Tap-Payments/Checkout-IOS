//
//  CheckoutViewController+Network.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//


import UIKit
import SharedDataModels_iOS
import CoreTelephony
import SwiftEntryKit
import WebKit

extension CheckoutViewController {
    func getIP() {
        let url = URL(string: "https://geolocation-db.com/json/")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  error == nil,
                  let jsonIP: [String: Any] = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                  let ipString: String = jsonIP["IPv4"] as? String else { return }
            
            self.detectedIP = ipString
        }
        task.resume()
    }
    
    func passIP() {
        webView?.evaluateJavaScript("window.setIP('\(detectedIP)')")
    }
    
    func getCDNURL() {
        if let url = URL(string: "https://tap-sdks.b-cdn.net/mobile/checkout/base_url.json") {
            var cdnRequest = URLRequest(url: url)
            cdnRequest.timeoutInterval = 2
            cdnRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            URLSession.shared.dataTask(with: cdnRequest) { data, response, error in
                self.setLoadedDataFromCDN(data: data)
                // we need to update the intent with the sdk info
                self.getCheckoutSDkConfig(configDict: self.configurations)
            }.resume()
        } else {
            // Use the default embedded values as a fallback of all we need to update the intent with the sdk info
            self.getCheckoutSDkConfig(configDict: configurations)
        }
    }
    
    func setLoadedDataFromCDN(data: Data?) {
        if let data = data {
            do {
                if let cdnResponse: [String: String] = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                   let cdnBaseUrlString: String = cdnResponse["baseURL"], cdnBaseUrlString != "",
                   let cdnBaseUrl: URL = URL(string: cdnBaseUrlString),
                   let sandboxEncryptionKey: String = cdnResponse["testEncKey"],
                   let productionEncryptionKey: String = cdnResponse["prodEncKey"] {
                    CheckoutViewController.sandboxKey = sandboxEncryptionKey
                    CheckoutViewController.productionKey = productionEncryptionKey
                    CheckoutViewController.tabCheckoutConfigUrl = cdnBaseUrlString
                }
            } catch {}
        }
    }
    
    func getCheckoutSDkConfig(configDict: [String: Any]) {
        if let url = URL(string: "\(CheckoutViewController.tabCheckoutConfigUrl)checkout/config") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            var updatedConfigurations = self.configurations.updatingAllOccurrences(ofKey: "cardNFC", with: false)
            updatedConfigurations["headers"] = generateApplicationHeader()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: updatedConfigurations, options: [])
                // Create a URLSession task to make the request
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        self.handleError(data: "\(error)")
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.handleError(data: "Invalid response")
                        return
                    }
                    
                    
                    if let data = data {
                        do {
                            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                if let redirectUrlString = jsonResponse["redirect_url"] as? String {
                                    CheckoutViewController.tabCheckoutUrl = redirectUrlString + "&platform=mobile"
//                                    CheckoutViewController.tabCheckoutUrl = redirectUrlString self.transformURlFromConfig(redirectUrlString)
                                    self.postLoadingFromCDN()
                                }
                            }
                        } catch {
                            if let responseString = String(data: data, encoding: .utf8) {
                                self.handleError(data: "Response string: \(responseString)")
                                return
                            }
                            self.handleError(data: "Error parsing response: \(error)")
                        }
                    }
                }.resume()
                
            } catch {
                self.handleError(data: "Error creating request body: \(error)")
            }
        }
    }
    
    func postLoadingFromCDN() {
        do {
            let url = URL(string: CheckoutViewController.tabCheckoutUrl)!
            try openUrl(url: url)
        } catch {
            handleError(data: "{error:\(error.localizedDescription)}")
        }
    }
    
    private func openUrl(url: URL?) {
        var request = URLRequest(url: url!)
        request.setValue(TapApplicationPlistInfo.shared.bundleIdentifier ?? "", forHTTPHeaderField: "referer")
        DispatchQueue.main.async {
            self.webView?.navigationDelegate = self
            self.webView?.load(request)
        }
    }
    
    func transformURlFromConfig(_ configUrl: String) -> String {
        var transformedUrl = configUrl
        
        // Replace either of the possible domains
        if transformedUrl.contains("https://checkout.dev.tap.company") {
            transformedUrl = transformedUrl.replacingOccurrences(
                of: "https://checkout.dev.tap.company",
                with: "https://tap-checkout-wrapper.netlify.app"
            )
        } else if transformedUrl.contains("https://checkout.staging.tap.company") {
            transformedUrl = transformedUrl.replacingOccurrences(
                of: "https://checkout.staging.tap.company",
                with: "https://tap-checkout-wrapper.netlify.app"
            )
        }
        
        // Add platform parameter if it doesn't already have one
        if !transformedUrl.contains("platform=") {
            // Check if we need to add a ? or & before the parameter
            if transformedUrl.contains("?") {
                transformedUrl += "&platform=mobile"
            } else {
                transformedUrl += "?platform=mobile"
            }
        }
        
        return transformedUrl
    }
    
}
