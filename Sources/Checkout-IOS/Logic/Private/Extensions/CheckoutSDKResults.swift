//
//  CheckoutSdkResults.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//


internal protocol CheckoutSDKResults: AnyObject {
    func onReady()
    func onSuccess(data: String)
    func onError(data: String)
    func onClose()
    func onChargeCreated(data: String)
}
    
