//
//  CheckoutSettings.swift
//  SPMExample
//
//  Every input of the Tap web demo (https://demo.tap.company/v2/sdk/checkout), stored in
//  UserDefaults (the web demo keeps the same state in localStorage), plus the mapping that turns
//  them into the configuration dictionary passed to `CheckoutSDK().start(configurations:delegate:)`.
//  The mapping mirrors what the web demo sends to the web SDK, so both behave the same.
//

import Foundation

struct CheckoutSettings: Codable {

    // MARK: - Order item

    struct OrderItem: Codable {
        var name = "Item Title 1"
        var description = "item description 1"
        var quantity = 1
        var amount = 0.1
    }

    // MARK: - SDK configuration

    var publicKey = Keys.publicKey
    var merchantId = Keys.merchantId
    /// Any of ALL, AUTO, KWD, BHD, SAR, AED, OMR, EGP, GBP, USD, EUR.
    var supportedCurrencies = ["ALL"]
    /// ALL, WEB, CARD or DEVICE.
    var paymentType = "ALL"
    var supportedPaymentMethods = ["ALL"]
    var selectedCurrency = "SAR"
    /// auto, en or ar. "auto" lets the checkout decide, so the key is not sent.
    var language = "en"
    var supportedRegions: [String] = []
    var supportedCountries: [String] = []
    var supportedPaymentTypes: [String] = []
    var supportedSchemes: [String] = []
    var isApplePayAvailableOnClient = true

    // MARK: - User configuration

    var customerId = ""
    var firstName = "Ahmed"
    var lastName = "Sharkawy"
    var email = "example@gmail.com"
    var countryCode = "20"
    var phoneNumber = "1099137773"

    // MARK: - Card configuration

    var showBrands = true
    var showLoadingState = false
    var collectHolderName = true
    var preLoadCardName = ""
    var cardNameEditable = true
    /// all, credit or debit.
    var cardFundingSource = "all"
    /// all, merchant, tap or none.
    var saveCardOption = "all"
    var forceLtr = false
    /// iOS only, not in the web demo: shows the native card scanner button (needs NSCameraUsageDescription).
    var cardScanner = false

    // MARK: - Order configuration

    var orderId = ""
    /// "F" = fixed amount, "P" = percentage of the items total.
    var discountType = "F"
    var discountValue = 0.0
    var items = [OrderItem()]

    // MARK: - Transaction configuration

    /// "charge" or "authorize".
    var mode = "charge"
    /// light, dark, light_mono, dark_colored or auto ("auto" = key not sent).
    var theme = "light"
    /// popup or page.
    var checkoutMode = "popup"
    var threeDSecure = true
    var saveCard = true
    /// `transaction.<mode>.redirect.url`; the web demo returns to its own page.
    var redirectUrl = CheckoutSettings.redirectURL
    var hashString = ""
    /// CAPTURE or VOID: what happens automatically to an authorization. Only editable in authorize mode.
    var authorizeType = "VOID"
    /// Hours before `authorizeType` is applied.
    var authorizeTime = 100
    var agreedPayment = false
    /// SCHEDULED or UNSCHEDULED.
    var agreementType = "SCHEDULED"
    /// FIXED or VARIABLE.
    var amountVariability = "FIXED"
    /// "Defined" (use `paymentCount`) or "Undefined" (txn_count 0).
    var numberOfPayments = "Undefined"
    var paymentCount = 1
    var subscriptionName = "Recurring"
    var subscriptionDescription = "A description of the recurring payment to display to the user in the payment sheet."
    var billingAgreement = "A localized billing agreement displayed to the user in the payment sheet prior to the payment authorization."
    /// "", "yes" or "no". The web demo starts with the airline choice unset and then still sends
    /// `airline` with an empty booking reference; only an explicit "no" removes it.
    var airline = ""
    var bookingReference = ""

    // MARK: - Persistence

    private static let storageKey = "CheckoutSettings.v1"

    /// Loads the saved settings, or the web demo defaults when nothing valid is saved.
    static func load(from defaults: UserDefaults = .standard) -> CheckoutSettings {
        guard let data = defaults.data(forKey: storageKey),
              var settings = try? JSONDecoder().decode(CheckoutSettings.self, from: data) else {
            return CheckoutSettings()
        }
        // A key saved while Keys.swift still held the placeholder follows Keys.swift once it is filled in.
        if settings.publicKey == placeholderPublicKey { settings.publicKey = Keys.publicKey }
        return settings
    }

    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: - Derived values

    static let placeholderPublicKey = "YOUR_TAP_PUBLIC_KEY"

    /// The page the web demo returns to after a redirect. The native SDK ignores it, but the
    /// checkout config still expects `transaction.<mode>.redirect.url`.
    static let redirectURL = "https://demo.tap.company/v2/sdk/checkout"

    var hasPublicKey: Bool {
        let key = publicKey.trimmingCharacters(in: .whitespaces)
        return !key.isEmpty && key != Self.placeholderPublicKey
    }

    /// Sum of `amount * quantity` over all items.
    var itemsTotal: Double {
        items.reduce(0) { $0 + $1.amount * Double($1.quantity) }
    }

    /// Amount charged: items total minus the discount, or 1 when that is zero or negative (as the web demo does).
    var totalAmount: Double {
        let discount = discountType == "P" ? itemsTotal * (discountValue / 100) : discountValue
        let total = itemsTotal - discount
        return total <= 0 ? 1 : total
    }

    // MARK: - Configuration dictionary

    /// Builds the dictionary for `CheckoutSDK().start(configurations:delegate:)`, following the web demo's mapping.
    func makeConfiguration() -> [String: Any] {
        var config: [String: Any] = [
            "open": true,
            "hashString": hashString,
            "checkoutMode": checkoutMode,
            "paymentType": paymentType,
            "supportedPaymentMethods": supportedPaymentMethods.contains("ALL") ? "ALL" : supportedPaymentMethods,
            "selectedCurrency": selectedCurrency,
            "supportedCurrencies": collapsedCurrencies,
            "gateway": gateway,
            "customer": customer,
            "transaction": ["mode": mode, mode: transaction],
            "amount": Self.jsonNumber(totalAmount),
            "order": order,
            "cardOptions": [
                "showBrands": showBrands,
                "showLoadingState": showLoadingState,
                "collectHolderName": collectHolderName,
                "preLoadCardName": preLoadCardName,
                "cardNameEditable": cardNameEditable,
                "cardFundingSource": cardFundingSource,
                "saveCardOption": saveCardOption,
                "forceLtr": forceLtr,
            ].merging(cardScanner ? ["alternativeCardInputs": ["cardScanner": true]] : [:]) { $1 },
            "isApplePayAvailableOnClient": isApplePayAvailableOnClient,
        ]

        // "auto" means "let the checkout decide": the key is not sent at all.
        if language != "auto" { config["language"] = language }
        if theme != "auto" { config["themeMode"] = theme }

        // Empty filters are not sent.
        if !supportedRegions.isEmpty { config["supportedRegions"] = supportedRegions }
        if !supportedCountries.isEmpty { config["supportedCountries"] = supportedCountries }
        if !supportedPaymentTypes.isEmpty { config["supportedPaymentTypes"] = supportedPaymentTypes }
        if !supportedSchemes.isEmpty { config["supportedSchemes"] = supportedSchemes }
        return config
    }

    /// ALL wins over AUTO, which wins over an explicit list.
    private var collapsedCurrencies: Any {
        if supportedCurrencies.contains("ALL") { return "ALL" }
        if supportedCurrencies.contains("AUTO") { return "AUTO" }
        return supportedCurrencies
    }

    private var gateway: [String: Any] {
        var gateway: [String: Any] = ["publicKey": publicKey]
        if !merchantId.isEmpty { gateway["merchantId"] = merchantId }
        return gateway
    }

    private var customer: [String: Any] {
        var customer: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": ["countryCode": countryCode, "number": phoneNumber],
        ]
        if !customerId.isEmpty { customer["id"] = customerId }
        return customer
    }

    private var order: [String: Any] {
        var order: [String: Any] = [
            "id": orderId,
            "currency": selectedCurrency,
            "amount": Self.jsonNumber(totalAmount),
            "items": items.map { item -> [String: Any] in
                [
                    "amount": Self.jsonNumber(item.amount),
                    "currency": selectedCurrency,
                    "name": item.name,
                    "quantity": item.quantity,
                    "description": item.description,
                ]
            },
        ]
        if discountValue > 0 {
            order["discount"] = ["type": discountType, "value": Self.jsonNumber(discountValue)]
        }
        return order
    }

    /// The `transaction.<mode>` object. Charge and authorize send the very same keys; only the
    /// name of this object (and `transaction.mode`) differs.
    private var transaction: [String: Any] {
        var transaction: [String: Any] = [
            "saveCard": saveCard,
            // Sent in both modes. `type` and `time` only matter (and are only editable) for authorizations.
            "auto": ["type": authorizeType, "time": authorizeTime],
            "redirect": ["url": redirectUrl],
            "threeDSecure": threeDSecure,
        ]

        if agreedPayment {
            transaction["agreement"] = agreementType == "UNSCHEDULED"
                ? ["type": "UNSCHEDULED"]
                : ["type": agreementType, "amount_variability": amountVariability]
            transaction["applePayRecurringPaymentRequest"] = applePayRecurringPaymentRequest
        }

        // Like the web demo, `subscription` does not depend on "Agreed payment": it is sent
        // whenever the agreement type is not UNSCHEDULED (which is the default).
        if agreementType != "UNSCHEDULED" {
            transaction["subscription"] = [
                "type": agreementType,
                "amount_variability": amountVariability,
                "txn_count": numberOfPayments == "Defined" ? paymentCount : 0,
            ] as [String: Any]
        }

        // Also like the web demo: sent unless the airline choice is explicitly "no".
        if airline != "no" {
            transaction["airline"] = ["reference": ["booking": bookingReference]]
        }
        return transaction
    }

    /// `JSONSerialization` writes a `Double` such as 0.1 as 0.10000000000000001. Rounding to 3 decimals
    /// (the most any currency uses) and passing a decimal number sends 0.1, like the web demo.
    private static func jsonNumber(_ value: Double) -> NSDecimalNumber {
        NSDecimalNumber(string: String(format: "%.3f", value))
    }

    private var applePayRecurringPaymentRequest: [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return [
            "paymentDescription": subscriptionDescription,
            "regularBilling": [
                "label": subscriptionName,
                "paymentTiming": "recurring",
                "recurringPaymentStartDate": formatter.string(from: Date()),
            ],
            "billingAgreement": billingAgreement,
            // The web demo uses the page origin for both URLs.
            "managementURL": "https://demo.tap.company",
            "tokenNotificationURL": "https://demo.tap.company",
        ]
    }
}
