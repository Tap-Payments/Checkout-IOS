//
//  CheckoutViewController+NetworkHeaders.swift
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
    func generateApplicationHeader() -> [String: String] {
        return [
            Constants.HTTPHeaderKey.application: applicationHeaderValue,
            Constants.HTTPHeaderKey.mdn: Crypter.encrypt(TapApplicationPlistInfo.shared.bundleIdentifier ?? "", using: headersEncryptionPublicKey) ?? ""
        ]
    }
    
    private var applicationHeaderValue: String {
        var applicationDetails = applicationStaticDetails()
        let localeIdentifier = "en"
        applicationDetails[Constants.HTTPHeaderValueKey.appLocale] = localeIdentifier
        let result = (applicationDetails.map { "\($0.key)=\($0.value)" }).joined(separator: "|")
        return result
    }
    
    func applicationStaticDetails() -> [String: String] {
        let bundleID = TapApplicationPlistInfo.shared.bundleIdentifier ?? ""
        let requirerVersion = CheckoutSDKVersion.current

        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let deviceName = UIDevice.current.name
        let deviceNameFiltered = deviceName.tap_byRemovingAllCharactersExcept("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789 ()")
        let deviceType = UIDevice.current.model
        let deviceModel = getDeviceCode() ?? ""
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        var simNetWorkName: String? = ""
        var simCountryISO: String? = ""
        
        if providers?.values.count ?? 0 > 0, let carrier: CTCarrier = providers?.values.first {
            simNetWorkName = carrier.carrierName
            simCountryISO = carrier.isoCountryCode
        }
        
        let result: [String: String] = [
            Constants.HTTPHeaderValueKey.appID: Crypter.encrypt(bundleID, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirer: Crypter.encrypt(Constants.HTTPHeaderValueKey.requirerValue, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerVersion: Crypter.encrypt(requirerVersion, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerOS: Crypter.encrypt(osName, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerOSVersion: Crypter.encrypt(osVersion, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceName: Crypter.encrypt(deviceNameFiltered, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceType: Crypter.encrypt(deviceType, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceModel: Crypter.encrypt(deviceModel, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerSimNetworkName: Crypter.encrypt(simNetWorkName ?? "", using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.requirerSimCountryIso: Crypter.encrypt(simCountryISO ?? "", using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.deviceID: Crypter.encrypt(deviceID, using: headersEncryptionPublicKey) ?? "",
            Constants.HTTPHeaderValueKey.appType: Crypter.encrypt("app", using: headersEncryptionPublicKey) ?? ""
        ]
        
        return result
    }
    
    func getDeviceCode() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode
    }
}
