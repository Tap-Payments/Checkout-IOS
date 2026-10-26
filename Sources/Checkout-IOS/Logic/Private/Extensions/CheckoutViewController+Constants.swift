//
//  CheckoutViewController+Constants.swift
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
    struct Constants {
        
        internal static let authenticateParameter = "authenticate"
        
        internal static let timeoutInterval: TimeInterval            = 60.0
        internal static let cachePolicy:     URLRequest.CachePolicy  = .reloadIgnoringCacheData
        
        internal static let successStatusCodes = 200...299
        
        internal struct HTTPHeaderKey {
            
            internal static let authorization            = "Authorization"
            internal static let application              = "application"
            internal static let sessionToken             = "session_token"
            internal static let contentTypeHeaderName    = "Content-Type"
            internal static let token                    = "session"
            internal static let mdn                      = "mdn"
            
            //@available(*, unavailable) private init() { }
        }
        
        internal struct HTTPHeaderValueKey {
            
            internal static let appID                    = "cu"
            internal static let appLocale                = "al"
            internal static let appType                  = "at"
            internal static let deviceID                 = "di"
            internal static let requirer                 = "aid"
            internal static let requirerOS               = "ro"
            internal static let requirerOSVersion        = "rov"
            internal static let requirerValue            = "card-ios"
            internal static let requirerVersion          = "av"
            internal static let requirerDeviceName       = "rn"
            internal static let requirerDeviceType       = "rt"
            internal static let requirerDeviceModel      = "rm"
            internal static let requirerSimNetworkName   = "rsn"
            internal static let requirerSimCountryIso    = "rsc"
            
            internal static let jsonContentTypeHeaderValue   = "application/json"
            
            //@available(*, unavailable) private init() { }
        }
    }
}
