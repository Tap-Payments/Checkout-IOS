//
//  UITestHooks.swift
//  SPMExample
//
//  Lets the UI tests (SPMExampleUITests) drive the app: start from default settings, use a
//  public key passed at launch, change any configuration key and start the checkout by itself.
//  Debug builds only, and only when a UI test sets these environment variables.
//

import Foundation

enum UITestHooks {
    #if DEBUG
    private static let environment = ProcessInfo.processInfo.environment
    #else
    private static let environment: [String: String] = [:]
    #endif

    /// True when the app was launched by a UI test.
    static var isActive: Bool { environment["UITEST"] == "1" }

    /// Start the checkout as soon as the main screen appears.
    static var autoStart: Bool { isActive && environment["UITEST_AUTOSTART"] == "1" }

    /// Called once at launch: UI tests always start from the web demo defaults.
    static func prepare() {
        guard isActive else { return }
        CheckoutSettings.reset()
    }

    /// Applies the test's changes on top of the configuration built from the settings.
    ///
    /// `UITEST_PUBLIC_KEY` replaces `gateway.publicKey`. `UITEST_CONFIG_OVERRIDES` is a JSON object
    /// merged into the configuration (nested objects are merged key by key); a `null` value removes
    /// that key, so a test can check what happens when it is not sent.
    static func apply(to configuration: [String: Any]) -> [String: Any] {
        guard isActive else { return configuration }
        var result = configuration
        if let key = environment["UITEST_PUBLIC_KEY"], !key.isEmpty {
            result = merge(result, ["gateway": ["publicKey": key]])
        }
        if let json = environment["UITEST_CONFIG_OVERRIDES"],
           let data = json.data(using: .utf8),
           let overrides = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            result = merge(result, overrides)
        }
        return result
    }

    static func merge(_ base: [String: Any], _ overrides: [String: Any]) -> [String: Any] {
        var result = base
        for (key, value) in overrides {
            if value is NSNull {
                result.removeValue(forKey: key)
            } else if let nested = value as? [String: Any], let current = result[key] as? [String: Any] {
                result[key] = merge(current, nested)
            } else {
                result[key] = value
            }
        }
        return result
    }
}
