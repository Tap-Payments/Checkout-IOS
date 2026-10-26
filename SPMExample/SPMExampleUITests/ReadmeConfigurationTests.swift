//
//  ReadmeConfigurationTests.swift
//  SPMExampleUITests
//
//  Checks, on a simulator against the Tap sandbox, that the configuration values documented in
//  README.md do what the README says on mobile. Each test starts the checkout with one value
//  changed (through UITestHooks in the app), then looks at the checkout sheet or at the charge the
//  server returns. Every test attaches a screenshot and prints a "RESULT |" line.
//
//  Run (the sandbox public key is passed in, never committed):
//    TEST_RUNNER_TAP_PUBLIC_KEY=pk_test_... xcodebuild test -project SPMExample/SPMExample.xcodeproj \
//      -scheme SPMExample -destination 'platform=iOS Simulator,name=iPhone 17'
//

import XCTest

final class ReadmeConfigurationTests: XCTestCase {

    private var app: XCUIApplication!
    private var publicKey = ""

    override func setUpWithError() throws {
        continueAfterFailure = true
        guard let key = ProcessInfo.processInfo.environment["TAP_PUBLIC_KEY"], !key.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_TAP_PUBLIC_KEY to a Tap sandbox public key to run these tests.")
        }
        publicKey = key
    }

    override func tearDown() {
        app?.terminate()
        super.tearDown()
    }

    // MARK: - SDK and gateway

    func testDefaultConfigurationOpensCheckout() {
        open()
        XCTAssertTrue(hasCardInput, "card input should be shown")
        result("defaults", "checkout opens, card input shown")
    }

    func testInvalidPublicKeyReportsError() {
        open(key: "pk_test_invalidKey000000000000", expectReady: false)
        let gotError = waitForCallback("onError", timeout: 30)
        XCTAssertTrue(gotError, "an invalid key should end in onError")
        XCTAssertFalse(log.contains("onReady"))
        result("gateway.publicKey invalid", gotError ? "onError" : "no onError")
    }

    func testUnknownMerchantId() {
        open(["gateway": ["merchantId": "000000"]], expectReady: false)
        let outcome = readyOrError()
        result("gateway.merchantId unknown", outcome)
    }

    func testHashString() {
        open(["hashString": "notARealHash"], expectReady: false)
        result("hashString invalid", readyOrError())
    }

    func testLanguageArabic() {
        open(["language": "ar"])
        XCTAssertTrue(hasArabicText, "Arabic text expected")
        result("language ar", hasArabicText ? "Arabic text shown" : "no Arabic text")
    }

    func testLanguageEnglish() {
        open(["language": "en"])
        XCTAssertFalse(hasArabicText, "no Arabic text expected")
        result("language en", hasArabicText ? "Arabic text shown" : "English only")
    }

    func testThemeLight() { checkTheme("light", dark: false) }
    func testThemeDark() { checkTheme("dark", dark: true) }
    func testThemeLightMono() { checkTheme("light_mono", dark: false) }
    func testThemeDarkColored() { checkTheme("dark_colored", dark: true) }

    func testPaymentTypeCard() {
        open(["paymentType": "CARD"])
        XCTAssertTrue(hasCardInput)
        result("paymentType CARD", hasCardInput ? "card input shown" : "no card input")
    }

    func testPaymentTypeWeb() {
        open(["paymentType": "WEB"], expectReady: false)
        let outcome = readyOrError()
        XCTAssertFalse(hasCardInput, "WEB should hide the card input")
        result("paymentType WEB", "\(outcome), card input \(hasCardInput ? "shown" : "hidden")")
    }

    func testPaymentTypeDevice() {
        open(["paymentType": "DEVICE"], expectReady: false)
        let outcome = readyOrError()
        XCTAssertFalse(hasCardInput, "DEVICE should hide the card input")
        result("paymentType DEVICE", "\(outcome), card input \(hasCardInput ? "shown" : "hidden")")
    }

    func testSupportedPaymentMethodsVisaOnly() {
        open(["supportedPaymentMethods": ["VISA"]])
        XCTAssertTrue(has("VISA"))
        XCTAssertFalse(has("MADA"), "MADA should not be offered")
        XCTAssertFalse(has("MASTERCARD"), "MASTERCARD should not be offered")
        result("supportedPaymentMethods [VISA]", "brands: \(brandsShown)")
    }

    func testSupportedSchemesVisaOnly() {
        open(["supportedSchemes": ["VISA"]])
        XCTAssertFalse(has("MADA"), "MADA should not be offered")
        result("supportedSchemes [VISA]", "brands: \(brandsShown)")
    }

    func testSupportedPaymentTypesCardOnly() {
        open(["supportedPaymentTypes": ["CARD"]])
        XCTAssertTrue(hasCardInput)
        result("supportedPaymentTypes [CARD]", "card input \(hasCardInput ? "shown" : "hidden") (see screenshot for wallets/BNPL)")
    }

    func testSupportedRegionsLocal() {
        open(["supportedRegions": ["LOCAL"]], expectReady: false)
        result("supportedRegions [LOCAL]", "\(readyOrError()), brands: \(brandsShown)")
    }

    func testSupportedCountriesSaudi() {
        open(["supportedCountries": ["SA"]], expectReady: false)
        result("supportedCountries [SA]", "\(readyOrError()), brands: \(brandsShown)")
    }

    func testSelectedCurrencyKWD() {
        open(["selectedCurrency": "KWD", "order": ["currency": "KWD", "items": [item(0.1, currency: "KWD")]]], expectReady: false)
        result("selectedCurrency KWD", readyOrError())
    }

    func testSupportedCurrenciesSarOnly() {
        open(["supportedCurrencies": ["SAR"]])
        XCTAssertFalse(has("Pay in"), "the 'Pay in <other currency>' option should be gone")
        result("supportedCurrencies [SAR]", has("Pay in") ? "other currency still offered" : "no other currency offered")
    }

    func testApplePayAvailableOnClientFalse() {
        open(["isApplePayAvailableOnClient": false])
        result("isApplePayAvailableOnClient false", "Apple Pay \(has("Apple Pay") || has("ApplePay") ? "shown" : "not shown") (see screenshot)")
    }

    func testOpenFalse() {
        open(["open": false], expectReady: false)
        result("open false", readyOrError())
    }

    // MARK: - Card options

    func testShowBrandsFalse() {
        open(["cardOptions": ["showBrands": false]])
        XCTAssertFalse(has("WE ACCEPT"), "brand list should be hidden")
        result("cardOptions.showBrands false", has("WE ACCEPT") ? "brands still shown" : "brands hidden")
    }

    func testShowLoadingStateTrue() {
        open(["cardOptions": ["showLoadingState": true]])
        result("cardOptions.showLoadingState true", "opens (see screenshot)")
    }

    func testCollectHolderNameFalse() {
        open(["cardOptions": ["collectHolderName": false]])
        enterTestCard(holder: nil)
        let nameFieldFocused = app.keyboards.keys["q"].exists || app.keyboards.keys["Q"].exists
        XCTAssertFalse(nameFieldFocused, "no card holder name field expected")
        result("cardOptions.collectHolderName false", nameFieldFocused ? "name field still asked" : "no name field")
    }

    func testPreLoadCardName() {
        open(["cardOptions": ["preLoadCardName": "John Doe"]])
        enterTestCard(holder: nil)
        let shown = has("JOHN DOE") || has("John Doe")
        XCTAssertTrue(shown, "the pre-loaded name should be filled in")
        result("cardOptions.preLoadCardName", shown ? "name pre-filled" : "name not pre-filled")
    }

    func testCardNameNotEditable() {
        open(["cardOptions": ["preLoadCardName": "John Doe", "cardNameEditable": false]])
        enterTestCard(holder: nil)
        typeSlowly("X")
        let changed = has("JOHN DOEX") || has("John DoeX")
        XCTAssertFalse(changed, "the name should not be editable")
        result("cardOptions.cardNameEditable false", changed ? "name could be edited" : "name not editable")
    }

    func testSaveCardOptionNone() {
        open(["cardOptions": ["saveCardOption": "none"]])
        enterTestCard(holder: "Test User")
        XCTAssertFalse(has("Save card"), "no save-card option expected")
        result("cardOptions.saveCardOption none", has("Save card") ? "save-card still shown" : "save-card hidden")
    }

    func testSaveCardOptionAll() {
        open()
        enterTestCard(holder: "Test User")
        XCTAssertTrue(has("Save card"), "save-card option expected")
        result("cardOptions.saveCardOption all", has("Save card") ? "save-card shown" : "save-card hidden")
    }

    func testCardFundingSourceCreditRejectsDebitCard() {
        // The sandbox test card 4508 7500 1574 1019 is a DEBIT card.
        open(["cardOptions": ["cardFundingSource": "credit"]])
        enterTestCard(holder: "Test User")
        let paid = payAndFinish().contains("\"status\":\"CAPTURED\"")
        XCTAssertFalse(paid, "a debit card should not be charged when only credit is allowed")
        result("cardOptions.cardFundingSource credit", paid ? "debit card was charged" : "debit card refused")
    }

    func testForceLtrWithArabic() {
        open(["language": "ar", "cardOptions": ["forceLtr": true]])
        result("cardOptions.forceLtr true (ar)", "opens (see screenshot)")
    }

    func testCardScannerOn() {
        open(["cardOptions": ["alternativeCardInputs": ["cardScanner": true]]])
        result("cardOptions.alternativeCardInputs.cardScanner true", "opens (see screenshot for the scan button)")
    }

    func testCardScannerOff() {
        open()
        result("cardScanner omitted", "opens (see screenshot, no scan button expected)")
    }

    // MARK: - Payments: customer, order and transaction

    func testChargeIsCapturedWithCustomerAndAirline() {
        open()
        enterTestCard(holder: "Test User")
        let charge = payAndFinish()
        XCTAssertTrue(charge.contains("\"status\":\"CAPTURED\""), "charge should be CAPTURED")
        XCTAssertTrue(charge.contains("\"first_name\":\"Ahmed\""), "customer.firstName")
        XCTAssertTrue(charge.contains("\"last_name\":\"Sharkawy\""), "customer.lastName")
        XCTAssertTrue(charge.contains("\"email\":\"example@gmail.com\""), "customer.email")
        XCTAssertTrue(charge.contains("\"country_code\":\"20\""), "customer.phone.countryCode")
        XCTAssertTrue(charge.contains("\"number\":\"1099137773\""), "customer.phone.number")
        XCTAssertTrue(charge.contains("\"airline\":{\"id\""), "airline sent by default")
        result("transaction.mode charge", summary(of: charge))
    }

    func testAuthorizeWithAutoVoid() {
        open(["transaction": authorize(auto: "VOID")])
        enterTestCard(holder: "Test User")
        let auth = payAndFinish()
        XCTAssertTrue(auth.contains("\"status\":\"AUTHORIZED\""), "authorization expected")
        XCTAssertTrue(auth.contains("\"type\":\"VOID\""), "auto.type VOID")
        result("transaction.mode authorize + auto VOID", summary(of: auth))
    }

    func testAuthorizeWithAutoCapture() {
        open(["transaction": authorize(auto: "CAPTURE")])
        enterTestCard(holder: "Test User")
        let auth = payAndFinish()
        XCTAssertTrue(auth.contains("\"status\":\"AUTHORIZED\""), "authorization expected")
        XCTAssertTrue(auth.contains("\"type\":\"CAPTURE\""), "auto.type CAPTURE")
        result("transaction.mode authorize + auto CAPTURE", summary(of: auth))
    }

    func testThreeDSecureOff() {
        open(["transaction": ["charge": ["threeDSecure": false]]])
        enterTestCard(holder: "Test User")
        let charge = payAndFinish()
        result("transaction.charge.threeDSecure false", "\(summary(of: charge)), 3DS page \(sawThreeDSPage ? "shown" : "not shown")")
    }

    func testOrderWithTwoItemsAndDiscount() {
        // 0.1 + 0.2 = 0.3, minus 10 % = 0.27.
        open([
            "amount": 0.27,
            "order": ["amount": 0.27, "items": [item(0.1), item(0.2, name: "Item Title 2")], "discount": ["type": "P", "value": 10]],
        ])
        enterTestCard(holder: "Test User")
        let charge = payAndFinish()
        XCTAssertTrue(charge.contains("\"amount\":0.27"), "the discounted total should be charged")
        result("order: 2 items + 10% discount", summary(of: charge))
    }

    func testAgreementUnscheduled() {
        open(["transaction": ["charge": ["agreement": ["type": "UNSCHEDULED"], "subscription": NSNull()]]], expectReady: false)
        result("transaction.charge.agreement UNSCHEDULED", readyOrError())
    }

    // MARK: - Launching and waiting

    /// Launches the app, which starts the checkout with `overrides` applied, and waits for onReady.
    private func open(_ overrides: [String: Any] = [:], key: String? = nil, expectReady: Bool = true) {
        app = XCUIApplication()
        app.launchEnvironment["UITEST"] = "1"
        app.launchEnvironment["UITEST_AUTOSTART"] = "1"
        app.launchEnvironment["UITEST_PUBLIC_KEY"] = key ?? publicKey
        if !overrides.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: overrides),
           let json = String(data: data, encoding: .utf8) {
            app.launchEnvironment["UITEST_CONFIG_OVERRIDES"] = json
        }
        app.launch()
        guard expectReady else { return }
        XCTAssertTrue(waitForCallback("onReady", timeout: 45), "checkout did not become ready. Log: \(log)")
        settle()
    }

    private var log: String { app.textViews["callbackLog"].value as? String ?? "" }

    @discardableResult
    private func waitForCallback(_ name: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if log.contains(name) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        return false
    }

    /// Waits for onReady or onError, whichever comes first.
    private func readyOrError() -> String {
        let deadline = Date().addingTimeInterval(45)
        while Date() < deadline {
            if log.contains("onError") { settle(); return "onError: " + (log.components(separatedBy: "onError: ").last ?? "").prefix(160) }
            if log.contains("onReady") { settle(); return "opens (onReady)" }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        return "neither onReady nor onError within 45 s"
    }

    /// Gives the web page a moment to finish drawing after onReady.
    private func settle(_ seconds: TimeInterval = 3) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Reading the checkout sheet

    private func has(_ text: String) -> Bool {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch.exists
    }

    private var hasCardInput: Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "card-icon-container")).firstMatch.exists
    }

    private var hasArabicText: Bool {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES %@", ".*[\\u0600-\\u06FF].*"))
            .firstMatch.exists
    }

    private var brandsShown: String {
        let brands = ["VISA", "MASTERCARD", "MADA", "AMERICAN_EXPRESS", "UNIONPAY", "BENEFIT", "OMANNET", "JAYWAN", "MAAL"]
        let shown = brands.filter { app.images[$0].exists }
        return shown.isEmpty ? "none" : shown.joined(separator: ", ")
    }

    private func checkTheme(_ theme: String, dark: Bool) {
        open(["themeMode": theme])
        let brightness = sheetBrightness()
        if dark {
            XCTAssertLessThan(brightness, 0.4, "\(theme) should give a dark sheet")
        } else {
            XCTAssertGreaterThan(brightness, 0.6, "\(theme) should give a light sheet")
        }
        result("themeMode \(theme)", String(format: "sheet brightness %.2f (%@)", brightness, brightness < 0.5 ? "dark" : "light"))
    }

    /// Average brightness (0 black, 1 white) of the lower part of the screen, where the sheet is.
    private func sheetBrightness() -> Double {
        guard let image = app.screenshot().image.cgImage else { return -1 }
        let width = 40, height = 40
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        // Draw only the bottom 30% of the screenshot.
        let crop = image.cropping(to: CGRect(x: 0, y: Int(Double(image.height) * 0.7), width: image.width, height: Int(Double(image.height) * 0.3)))
        context?.draw(crop ?? image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var total = 0.0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            total += (0.299 * Double(pixels[index]) + 0.587 * Double(pixels[index + 1]) + 0.114 * Double(pixels[index + 2])) / 255
        }
        return total / Double(width * height)
    }

    // MARK: - Paying with the sandbox 3DS test card

    private var sawThreeDSPage = false

    /// Types the sandbox test card 4508 7500 1574 1019, 01/39, CVV 100 (and the holder name if given).
    private func enterTestCard(holder: String?) {
        let icon = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "card-icon-container")).firstMatch
        guard icon.waitForExistence(timeout: 15) else { return XCTFail("card input not found") }
        icon.coordinate(withNormalizedOffset: CGVector(dx: 3, dy: 0.5)).tap()
        settle(1.5)
        for part in ["4508750015741019", "0139", "100"] {
            typeSlowly(part)
            settle(0.8)
        }
        if let holder {
            typeSlowly(holder)
            settle(0.8)
        }
        settle(1)
    }

    /// The checkout formats the card fields as you type and drops keys sent in one burst,
    /// so type one character at a time.
    private func typeSlowly(_ text: String) {
        for character in text {
            app.typeText(String(character))
            RunLoop.current.run(until: Date().addingTimeInterval(0.12))
        }
    }

    /// Taps Pay, approves the 3DS emulator if it appears, and returns the onChargeCreated payload
    /// (empty if the payment did not go through).
    private func payAndFinish() -> String {
        if app.buttons["Done"].exists { app.buttons["Done"].tap(); settle(1.5) }
        let width = app.windows.firstMatch.frame.width
        let payButton = app.webViews.buttons.allElementsBoundByIndex
            .filter { $0.frame.width > width * 0.8 }
            .max { $0.frame.minY < $1.frame.minY }
        guard let payButton else { XCTFail("pay button not found"); return "" }
        payButton.tap()

        let submit = app.buttons["Submit"]
        sawThreeDSPage = submit.waitForExistence(timeout: 30)
        if sawThreeDSPage { submit.tap() }

        let deadline = Date().addingTimeInterval(45)
        while Date() < deadline, !log.contains("onSuccess"), !log.contains("onError") {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        settle(1)
        return log.components(separatedBy: "onChargeCreated: ").dropFirst().first?.components(separatedBy: "\n\n").first ?? ""
    }

    // MARK: - Helpers

    private func item(_ amount: Double, name: String = "Item Title 1", currency: String = "SAR") -> [String: Any] {
        ["amount": amount, "currency": currency, "name": name, "quantity": 1, "description": "item description"]
    }

    /// A `transaction` object for authorize mode; the default `charge` object is removed.
    private func authorize(auto type: String) -> [String: Any] {
        [
            "mode": "authorize",
            "charge": NSNull(),
            "authorize": [
                "saveCard": true,
                "auto": ["type": type, "time": 100],
                "redirect": ["url": "https://demo.tap.company/v2/sdk/checkout"],
                "threeDSecure": true,
            ] as [String: Any],
        ]
    }

    private func summary(of payload: String) -> String {
        guard !payload.isEmpty else { return "no charge created. Log: " + log.prefix(200) }
        func field(_ name: String) -> String {
            guard let range = payload.range(of: "\"\(name)\":") else { return "?" }
            return String(payload[range.upperBound...].prefix { $0 != "," && $0 != "}" }).replacingOccurrences(of: "\"", with: "")
        }
        return "\(field("object")) \(field("status")) \(field("amount")) \(field("currency"))"
    }

    /// Prints a result line and attaches the current screen to the test report.
    private func result(_ name: String, _ outcome: String) {
        print("RESULT | \(name) | \(outcome)")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
