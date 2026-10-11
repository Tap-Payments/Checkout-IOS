//
//  CheckoutSDK.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation
import UIKit

public class CheckoutSDK {
    
    weak var delegate: CheckoutSDKDelegate?
    
    public init() {
        
    }
    
    public func start(configurations: [String : Any], delegate: CheckoutSDKDelegate) {
        let checkoutViewController = CheckoutViewController(configurations: configurations, results: self)
        self.delegate = delegate
        delegate.controller.present(checkoutViewController, animated: true)
    }
}

extension CheckoutSDK: CheckoutSDKResults {
    
    func onClose() {
        delegate?.onClose()
    }
    
    func onReady() {
        delegate?.onReady()
    }
    
    func onSuccess(data: String) {
        delegate?.onSuccess(data: data)
    }
    
    func onError(data: String) {
        delegate?.onError(data: data)
    }
    
    func onChargeCreated(data: String) {
        delegate?.onChargeCreated(data: data)
    }
}


public protocol CheckoutSDKDelegate: AnyObject {  
    var controller: UIViewController { get }
    func onClose()
    func onReady()
    func onSuccess(data: String)
    func onError(data: String)
    func onChargeCreated(data: String)
}
