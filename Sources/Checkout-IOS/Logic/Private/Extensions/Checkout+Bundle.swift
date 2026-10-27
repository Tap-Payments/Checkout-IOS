//
//  Checkout+Bundle.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation


internal extension Bundle {
    static var currentBundle:Bundle {
        // CocoaPods names the bundle from the podspec, SPM from the package and target names.
        // iOS devices have a case-sensitive file system, so both spellings are tried.
        let bundleNames = ["Checkout-iOS_Checkout-iOS", "Checkout-IOS_Checkout-IOS"]

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: CheckoutViewController.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            for bundleName in bundleNames {
                let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
                if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                    return bundle
                }
            }
        }
        return Bundle(for: CheckoutViewController.self)
    }
}
