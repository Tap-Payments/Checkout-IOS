//
//  CheckoutSettingsTests.swift
//  SPMExampleTests
//
//  Checks, without a network or the checkout sheet, that the configuration the example app sends
//  matches the defaults documented in README.md (which are the Tap web demo's) and the mapping rules
//  of the configuration reference. Same checks as CheckoutSettingsTest.kt in the Android repository.
//
//  Run:
//    xcodebuild test -project SPMExample/SPMExample.xcodeproj -scheme SPMExample \
//      -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SPMExampleTests
//

import XCTest
@testable import SPMExample

final class CheckoutSettingsTests: XCTestCase {

    private func config(_ change: (inout CheckoutSettings) -> Void = { _ in }) -> [String: Any] {
        var settings = CheckoutSettings()
        settings.publicKey = "pk_test_x"
        change(&settings)
        return settings.makeConfiguration()
    }

    /// Compares JSON-like values (dictionaries, arrays, strings, numbers, booleans).
    private func assertJSONEqual(_ actual: Any?, _ expected: Any, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        guard let actual else { return XCTFail("missing value. \(message)", file: file, line: line) }
        XCTAssertEqual(actual as? NSObject, expected as? NSObject, message, file: file, line: line)
    }

    private func dictionary(_ value: Any?) -> [String: Any] { value as? [String: Any] ?? [:] }

    private func number(_ text: String) -> NSDecimalNumber { NSDecimalNumber(string: text) }

    func testDefaultsMatchTheReadme() {
        let config = config()
        assertJSONEqual(config["open"], true)
        assertJSONEqual(config["hashString"], "")
        assertJSONEqual(config["checkoutMode"], "popup")
        assertJSONEqual(config["language"], "en")
        assertJSONEqual(config["themeMode"], "light")
        assertJSONEqual(config["paymentType"], "ALL")
        assertJSONEqual(config["supportedPaymentMethods"], "ALL")
        assertJSONEqual(config["selectedCurrency"], "SAR")
        assertJSONEqual(config["supportedCurrencies"], "ALL")
        assertJSONEqual(config["isApplePayAvailableOnClient"], true)
        assertJSONEqual(config["amount"], number("0.1"))
        assertJSONEqual(config["gateway"], ["publicKey": "pk_test_x"])
        for key in ["supportedRegions", "supportedCountries", "supportedPaymentTypes", "supportedSchemes"] {
            XCTAssertNil(config[key], "\(key) should be omitted")
        }
    }

    func testCustomerDefaults() {
        assertJSONEqual(config()["customer"], [
            "firstName": "Ahmed", "lastName": "Sharkawy", "email": "example@gmail.com",
            "phone": ["countryCode": "20", "number": "1099137773"],
        ] as [String: Any])
        assertJSONEqual(dictionary(config { $0.customerId = "cus_1" }["customer"])["id"], "cus_1")
    }

    func testCardOptionDefaults() {
        assertJSONEqual(config()["cardOptions"], [
            "showBrands": true, "showLoadingState": false, "collectHolderName": true, "preLoadCardName": "",
            "cardNameEditable": true, "cardFundingSource": "all", "saveCardOption": "all", "forceLtr": false,
        ] as [String: Any])
        let withScanner = dictionary(config { $0.cardScanner = true }["cardOptions"])
        assertJSONEqual(withScanner["alternativeCardInputs"], ["cardScanner": true])
    }

    func testOrderDefaults() {
        let order = dictionary(config()["order"])
        assertJSONEqual(order["id"], "")
        assertJSONEqual(order["currency"], "SAR")
        assertJSONEqual(order["amount"], number("0.1"))
        assertJSONEqual(order["items"], [[
            "amount": number("0.1"), "currency": "SAR", "name": "Item Title 1", "quantity": 1, "description": "item description 1",
        ] as [String: Any]])
        XCTAssertNil(order["discount"], "no discount by default")
    }

    func testChargeTransactionDefaults() {
        let transaction = dictionary(config()["transaction"])
        assertJSONEqual(transaction["mode"], "charge")
        assertJSONEqual(transaction["charge"], [
            "saveCard": true,
            "auto": ["type": "VOID", "time": 100],
            "redirect": ["url": "https://demo.tap.company/v2/sdk/checkout"],
            "threeDSecure": true,
            "subscription": ["type": "SCHEDULED", "amount_variability": "FIXED", "txn_count": 0],
            "airline": ["reference": ["booking": ""]],
        ] as [String: Any])
    }

    func testAuthorizeUsesAnObjectNamedAfterTheMode() {
        let transaction = dictionary(config { $0.mode = "authorize"; $0.authorizeType = "CAPTURE" }["transaction"])
        assertJSONEqual(transaction["mode"], "authorize")
        XCTAssertNil(transaction["charge"])
        assertJSONEqual(dictionary(transaction["authorize"])["auto"], ["type": "CAPTURE", "time": 100] as [String: Any])
    }

    func testDiscountAndTotals() {
        var second = CheckoutSettings.OrderItem()
        second.name = "Item Title 2"
        second.amount = 0.2
        let percent = config { $0.items = [CheckoutSettings.OrderItem(), second]; $0.discountType = "P"; $0.discountValue = 10 }
        assertJSONEqual(percent["amount"], number("0.27"))
        assertJSONEqual(dictionary(percent["order"])["discount"], ["type": "P", "value": number("10")] as [String: Any])

        let tooMuch = config { $0.discountType = "F"; $0.discountValue = 5 }
        assertJSONEqual(tooMuch["amount"], number("1"), "a total of 0 or less becomes 1, like the web demo")

        var three = CheckoutSettings.OrderItem()
        three.quantity = 3
        assertJSONEqual(config { $0.items = [three] }["amount"], number("0.3"))
    }

    func testAutoAndEmptyValuesAreNotSent() {
        let config = config { $0.language = "auto"; $0.theme = "auto" }
        XCTAssertNil(config["language"])
        XCTAssertNil(config["themeMode"])
        XCTAssertNil(dictionary(config["gateway"])["merchantId"])
    }

    func testListsAndCollapsing() {
        assertJSONEqual(config { $0.supportedCurrencies = ["AUTO", "SAR"] }["supportedCurrencies"], "AUTO")
        assertJSONEqual(config { $0.supportedCurrencies = ["SAR", "ALL"] }["supportedCurrencies"], "ALL")
        assertJSONEqual(config { $0.supportedCurrencies = ["SAR", "KWD"] }["supportedCurrencies"], ["SAR", "KWD"])
        assertJSONEqual(config { $0.supportedPaymentMethods = ["VISA"] }["supportedPaymentMethods"], ["VISA"])
        assertJSONEqual(config { $0.supportedCountries = ["SA"] }["supportedCountries"], ["SA"])
    }

    func testAgreementAndSubscription() {
        let unscheduled = dictionary(dictionary(config { $0.agreedPayment = true; $0.agreementType = "UNSCHEDULED" }["transaction"])["charge"])
        assertJSONEqual(unscheduled["agreement"], ["type": "UNSCHEDULED"])
        XCTAssertNil(unscheduled["subscription"], "no subscription when UNSCHEDULED")
        XCTAssertNotNil(unscheduled["applePayRecurringPaymentRequest"])

        let defined = dictionary(dictionary(config {
            $0.agreedPayment = true; $0.numberOfPayments = "Defined"; $0.paymentCount = 4
        }["transaction"])["charge"])
        assertJSONEqual(defined["agreement"], ["type": "SCHEDULED", "amount_variability": "FIXED"])
        assertJSONEqual(dictionary(defined["subscription"])["txn_count"], 4)
    }

    func testAirlineIsSentUnlessNo() {
        XCTAssertNil(dictionary(dictionary(config { $0.airline = "no" }["transaction"])["charge"])["airline"])
        let yes = dictionary(dictionary(config { $0.airline = "yes"; $0.bookingReference = "ABC123" }["transaction"])["charge"])
        assertJSONEqual(yes["airline"], ["reference": ["booking": "ABC123"]])
    }

    func testPlaceholderKeyIsNotAKey() {
        var settings = CheckoutSettings()
        settings.publicKey = CheckoutSettings.placeholderPublicKey
        XCTAssertFalse(settings.hasPublicKey)
        settings.publicKey = "  "
        XCTAssertFalse(settings.hasPublicKey)
        settings.publicKey = "pk_test_x"
        XCTAssertTrue(settings.hasPublicKey)
    }

    func testTestOverridesMergeAndRemove() {
        let merged = UITestHooks.merge(config(), [
            "language": "ar", "cardOptions": ["showBrands": false], "hashString": NSNull(),
        ])
        assertJSONEqual(merged["language"], "ar")
        assertJSONEqual(dictionary(merged["cardOptions"])["showBrands"], false)
        assertJSONEqual(dictionary(merged["cardOptions"])["saveCardOption"], "all", "other card options are kept")
        XCTAssertNil(merged["hashString"])
    }

    func testSettingsSurviveSaveAndLoad() {
        let defaults = UserDefaults(suiteName: "CheckoutSettingsTests")!
        defaults.removePersistentDomain(forName: "CheckoutSettingsTests")
        var settings = CheckoutSettings()
        settings.mode = "authorize"
        settings.items.append(CheckoutSettings.OrderItem())
        settings.save(to: defaults)
        let loaded = CheckoutSettings.load(from: defaults)
        XCTAssertEqual(loaded.mode, "authorize")
        XCTAssertEqual(loaded.items.count, 2)
        CheckoutSettings.reset(in: defaults)
        XCTAssertEqual(CheckoutSettings.load(from: defaults).mode, "charge", "reset goes back to the defaults")
    }
}
