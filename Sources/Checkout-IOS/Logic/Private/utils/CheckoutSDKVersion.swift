//
//  CheckoutSDKVersion.swift
//  Checkout-IOS
//

/// The SDK version reported to Tap in the request headers.
///
/// Single source of truth: `Checkout-IOS.podspec` reads its `s.version` from this
/// line, so bump the version here and tag the release with the same number.
/// It can't be read from `Bundle(for:)` because under SPM the SDK is linked into
/// the host app and that bundle is the merchant app's, not the SDK's.
internal enum CheckoutSDKVersion {
    static let current = "1.0.5"
}
