//
//  ViewController.swift
//  SPMExample
//
//  Checkout-IOS integration: build the configuration from the saved settings, start the checkout
//  and log every callback. The Settings screen edits the same inputs as the Tap web demo.
//
//  The screen shows what the next checkout will do (mode, amount, key), the main settings, and every
//  callback as a card that expands to its full payload. Same layout as the Android example app.
//

import UIKit
import Checkout_IOS

class ViewController: UIViewController {

    private struct Callback {
        let name: String
        let time: String
        let payload: String?
    }

    private var callbacks: [Callback] = []

    /// Edited in the Settings screen and persisted in UserDefaults; reloaded whenever this screen appears.
    private var settings = CheckoutSettings.load()

    // MARK: Views

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let heroView = GradientView()
    private let modeLabel = UILabel()
    private let keyChip = PaddedLabel()
    /// What the next checkout will do: the amount and currency.
    private let summaryLabel = UILabel()
    private let detailLabel = UILabel()

    private let configCard = CardView()
    private let configRows = UIStackView()

    private let callbacksHeader = SectionHeader("Callbacks")
    private let clearButton = UIButton(type: .system)
    private let emptyCard = CardView()
    private let callbacksStack = UIStackView()

    /// Plain-text log of every callback; shown instead of the cards when a UI test runs.
    private lazy var callbacksTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 13)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 14
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.text = "Callbacks will appear here..."
        textView.accessibilityIdentifier = "callbackLog"
        return textView
    }()

    private lazy var checkoutButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .large
        configuration.baseBackgroundColor = .systemBlue
        configuration.imagePadding = 10
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 17, weight: .semibold)
            return attributes
        }
        configuration.title = "Start Checkout"
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(startCheckout), for: .touchUpInside)
        return button
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // Same bar as the Android example: a bold title on the left and a plain SETTINGS action.
        navigationItem.backButtonTitle = "Tap Checkout"
        let titleLabel = UILabel()
        titleLabel.text = "Tap Checkout"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        let titleItem = UIBarButtonItem(customView: titleLabel)
        let settingsItem = UIBarButtonItem(title: "SETTINGS", style: .plain, target: self, action: #selector(openSettings))
        settingsItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: UIColor.systemBlue], for: .normal)
        if #available(iOS 26.0, *) {
            titleItem.hidesSharedBackground = true
            settingsItem.hidesSharedBackground = true
        }
        navigationItem.leftBarButtonItem = titleItem
        navigationItem.rightBarButtonItem = settingsItem

        buildLayout()
        renderCallbacks()

        // UI tests read the plain-text log, so show it near the top instead of the cards.
        if UITestHooks.isActive {
            [heroView, configCard, emptyCard].forEach { $0.isHidden = true }
            callbacksTextView.isHidden = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings = CheckoutSettings.load()
        renderSummary()
        renderConfiguration()
    }

    private var didAutoStart = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UITestHooks.autoStart && !didAutoStart {
            didAutoStart = true
            startCheckout()
        }
    }

    // MARK: Layout

    private func buildLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkoutButton)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: checkoutButton.topAnchor, constant: -8),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),

            checkoutButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            checkoutButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            checkoutButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
            checkoutButton.heightAnchor.constraint(equalToConstant: 54),
        ])

        buildHero()
        contentStack.addArrangedSubview(heroView)
        contentStack.setCustomSpacing(24, after: heroView)

        contentStack.addArrangedSubview(SectionHeader("Configuration"))
        buildConfigCard()
        contentStack.addArrangedSubview(configCard)
        contentStack.setCustomSpacing(24, after: configCard)

        clearButton.setTitle("Clear", for: .normal)
        clearButton.addTarget(self, action: #selector(clearCallbacks), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [callbacksHeader, clearButton])
        header.alignment = .center
        contentStack.addArrangedSubview(header)

        let emptyLabel = UILabel()
        emptyLabel.text = "Callbacks will appear here.\nTap a callback to see its full payload."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyLabel.textColor = .secondaryLabel
        emptyCard.embed(emptyLabel, insets: UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16))
        contentStack.addArrangedSubview(emptyCard)

        callbacksStack.axis = .vertical
        callbacksStack.spacing = 8
        contentStack.addArrangedSubview(callbacksStack)

        callbacksTextView.isHidden = true
        contentStack.addArrangedSubview(callbacksTextView)
    }

    private func buildHero() {
        modeLabel.font = .systemFont(ofSize: 13, weight: .bold)
        modeLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        keyChip.font = .systemFont(ofSize: 12, weight: .bold)
        keyChip.textColor = .white
        keyChip.layer.cornerRadius = 11
        keyChip.layer.masksToBounds = true
        keyChip.setContentHuggingPriority(.required, for: .horizontal)

        summaryLabel.font = .systemFont(ofSize: 34, weight: .bold)
        summaryLabel.textColor = .white
        summaryLabel.adjustsFontSizeToFitWidth = true

        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        let topRow = UIStackView(arrangedSubviews: [modeLabel, keyChip])
        topRow.alignment = .center
        let stack = UIStackView(arrangedSubviews: [topRow, summaryLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.setCustomSpacing(10, after: topRow)
        heroView.layer.cornerRadius = 18
        heroView.clipsToBounds = true
        heroView.embed(stack, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    private func buildConfigCard() {
        configRows.axis = .vertical

        let editButton = UIButton(type: .system)
        editButton.setTitle("Edit settings", for: .normal)
        editButton.contentHorizontalAlignment = .leading
        editButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        let jsonButton = UIButton(type: .system)
        jsonButton.setTitle("View JSON", for: .normal)
        jsonButton.contentHorizontalAlignment = .trailing
        jsonButton.addTarget(self, action: #selector(showJSON), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [editButton, jsonButton])
        actions.distribution = .fillEqually
        actions.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let stack = UIStackView(arrangedSubviews: [configRows, actions])
        stack.axis = .vertical
        configCard.embed(stack, insets: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }

    // MARK: Summary and configuration

    private func renderSummary() {
        modeLabel.text = settings.mode == "authorize" ? "AUTHORIZE · \(settings.authorizeType)" : "CHARGE"
        summaryLabel.text = "\(settings.totalAmount.formatted) \(settings.selectedCurrency)"
        let count = settings.items.count
        let customer = "\(settings.firstName) \(settings.lastName)".trimmingCharacters(in: .whitespaces)
        detailLabel.text = "\(count) item\(count == 1 ? "" : "s") · \(customer)"

        let key = settings.publicKey.trimmingCharacters(in: .whitespaces)
        if !settings.hasPublicKey {
            keyChip.text = "No public key"
            keyChip.backgroundColor = .systemRed
        } else if key.hasPrefix("pk_live_") {
            keyChip.text = "Live key"
            keyChip.backgroundColor = .systemOrange
        } else {
            keyChip.text = "Sandbox key"
            keyChip.backgroundColor = .systemGreen
        }
    }

    private func renderConfiguration() {
        func list(_ values: [String]) -> String { values.isEmpty ? "All" : values.joined(separator: ", ") }
        let rows: [(String, String)] = [
            ("Payment type", settings.paymentType),
            ("Payment methods", list(settings.supportedPaymentMethods)),
            ("Currencies", list(settings.supportedCurrencies)),
            ("Language", settings.language),
            ("Theme", settings.theme),
            ("Checkout mode", settings.checkoutMode),
            ("3D Secure", settings.threeDSecure ? "On" : "Off"),
            ("Save card", settings.saveCardOption),
            ("Card funding", settings.cardFundingSource),
            ("Customer", "\(settings.email) · +\(settings.countryCode) \(settings.phoneNumber)"),
        ]
        configRows.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, row) in rows.enumerated() {
            if index > 0 { configRows.addArrangedSubview(Divider()) }
            configRows.addArrangedSubview(ConfigRow(label: row.0, value: row.1))
        }
        configRows.addArrangedSubview(Divider())
    }

    // MARK: Actions

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func showJSON() {
        let configuration = UITestHooks.apply(to: settings.makeConfiguration())
        navigationController?.pushViewController(ConfigurationJSONViewController(configuration: configuration), animated: true)
    }

    @objc private func clearCallbacks() {
        callbacks.removeAll()
        renderCallbacks()
    }

    @objc private func startCheckout() {
        guard settings.hasPublicKey || UITestHooks.isActive else {
            let alert = UIAlertController(
                title: "Public key missing",
                message: "Set your Tap sandbox public key in Keys.swift (Keys.publicKey), or enter it in Settings > SDK Configuration > Public Key.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        // The button shows a spinner until the checkout sheet is ready (or fails).
        setLoading(true)
        // The SDK takes a plain dictionary; `makeConfiguration()` builds it like the Tap web demo does.
        CheckoutSDK().start(configurations: UITestHooks.apply(to: settings.makeConfiguration()), delegate: self)
    }

    /// Until the sheet is ready, closes or fails. The SDK reports a checkout that cannot load through onError.
    private func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            var configuration = self.checkoutButton.configuration
            configuration?.showsActivityIndicator = loading
            configuration?.title = loading ? "Opening checkout…" : "Start Checkout"
            self.checkoutButton.configuration = configuration
            self.checkoutButton.isEnabled = !loading
        }
    }

    // MARK: Callbacks

    private func addCallback(_ name: String, payload: String?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let callback = Callback(name: name, time: formatter.string(from: Date()), payload: payload)
        DispatchQueue.main.async {
            self.callbacks.insert(callback, at: 0)
            self.renderCallbacks()
        }
    }

    private func logLine(_ callback: Callback) -> String {
        switch callback.name {
        case "onReady": return "onReady: Checkout is ready"
        case "onClose": return "onClose: Checkout was closed"
        default: return "\(callback.name): \(callback.payload ?? "")"
        }
    }

    private func renderCallbacks() {
        callbacksTextView.text = callbacks.isEmpty
            ? "Callbacks will appear here..."
            : callbacks.map { "[\($0.time)] \(logLine($0))" }.joined(separator: "\n\n")
        callbacksHeader.text = callbacks.isEmpty ? "CALLBACKS" : "CALLBACKS (\(callbacks.count))"
        clearButton.isHidden = callbacks.isEmpty
        emptyCard.isHidden = !callbacks.isEmpty || UITestHooks.isActive

        callbacksStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !UITestHooks.isActive else { return }
        for callback in callbacks {
            callbacksStack.addArrangedSubview(CallbackCard(
                name: callback.name,
                time: callback.time,
                summary: summary(of: callback),
                payload: callback.payload.map(prettyJSON),
                color: color(for: callback.name)
            ))
        }
    }

    private func color(for name: String) -> UIColor {
        switch name {
        case "onReady": return .systemBlue
        case "onChargeCreated": return .systemPurple
        case "onSuccess": return .systemGreen
        case "onError": return .systemRed
        default: return .systemGray
        }
    }

    /// One line that says what happened, read from the payload where there is one.
    private func summary(of callback: Callback) -> String {
        let json = callback.payload
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        func text(_ key: String) -> String? {
            guard let value = json?[key] else { return nil }
            let string = "\(value)"
            return string.isEmpty ? nil : string
        }
        let line: String?
        switch callback.name {
        case "onReady": line = "Checkout is ready"
        case "onClose": line = "Checkout was closed"
        case "onChargeCreated":
            let amount = [text("amount"), text("currency")].compactMap { $0 }.joined(separator: " ")
            line = [text("id"), text("status"), amount.isEmpty ? nil : amount].compactMap { $0 }.joined(separator: " · ")
        case "onSuccess": line = text("chargeId").map { "Completed · \($0)" }
        case "onError": line = text("message").map { message in text("code").map { "\(message) (\($0))" } ?? message }
        default: line = nil
        }
        return line ?? String((callback.payload ?? "").prefix(120))
    }

    private func prettyJSON(_ payload: String) -> String {
        guard let data = payload.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: pretty, encoding: .utf8) else { return payload }
        return text
    }
}

private extension Double {
    /// 0.1 -> "0.1", 10.0 -> "10" (no trailing ".0").
    var formatted: String {
        let text = String(self)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}

// MARK: - CheckoutSDKDelegate
extension ViewController: CheckoutSDKDelegate {
    var controller: UIViewController {
        return self
    }

    func onReady() {
        setLoading(false)
        addCallback("onReady", payload: nil)
    }

    func onChargeCreated(data: String) {
        addCallback("onChargeCreated", payload: data)
    }

    func onSuccess(data: String) {
        setLoading(false)
        addCallback("onSuccess", payload: data)
    }

    func onError(data: String) {
        setLoading(false)
        addCallback("onError", payload: data)
    }

    func onClose() {
        setLoading(false)
        addCallback("onClose", payload: nil)
    }
}

// MARK: - Building blocks

/// A rounded card on the grouped background.
private class CardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// The hero card's blue gradient.
private final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        if let gradient = layer as? CAGradientLayer {
            gradient.colors = [UIColor(red: 0.04, green: 0.52, blue: 1, alpha: 1).cgColor,
                               UIColor(red: 0.23, green: 0.23, blue: 0.85, alpha: 1).cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
        }
        layer.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

private extension UIView {
    func embed(_ child: UIView, insets: UIEdgeInsets) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            child.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
        ])
    }
}

private final class SectionHeader: UILabel {
    init(_ title: String) {
        super.init(frame: .zero)
        text = title.uppercased()
        font = .preferredFont(forTextStyle: .footnote)
        textColor = .secondaryLabel
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: size.height + 8)
    }
}

/// A label with padding, used for the key chip and the event badges.
private final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}

private final class Divider: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .separator
        heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

private final class ConfigRow: UIStackView {
    init(label: String, value: String) {
        super.init(frame: .zero)
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .secondaryLabel
        labelView.font = .systemFont(ofSize: 15)
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        labelView.setContentCompressionResistancePriority(.required, for: .horizontal)
        let valueView = UILabel()
        valueView.text = value
        valueView.textAlignment = .right
        valueView.lineBreakMode = .byTruncatingTail
        valueView.font = .systemFont(ofSize: 15)
        addArrangedSubview(labelView)
        addArrangedSubview(valueView)
        spacing = 16
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 11, leading: 0, bottom: 11, trailing: 0)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// One callback: event name, time and a one-line summary; tap to show the full payload,
/// long press to copy it.
private final class CallbackCard: CardView {
    private let payloadBox = CardView()
    private let payload: String?

    init(name: String, time: String, summary: String, payload: String?, color: UIColor) {
        self.payload = payload
        super.init(frame: .zero)

        let badge = PaddedLabel()
        badge.insets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
        badge.text = name
        badge.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = color
        badge.layer.cornerRadius = 10
        badge.layer.masksToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)

        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.font = .preferredFont(forTextStyle: .caption1)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right

        let topRow = UIStackView(arrangedSubviews: [badge, timeLabel])
        topRow.alignment = .center

        let summaryLabel = UILabel()
        summaryLabel.text = summary
        summaryLabel.numberOfLines = 0
        summaryLabel.font = .preferredFont(forTextStyle: .subheadline)

        let payloadLabel = UILabel()
        payloadLabel.text = payload
        payloadLabel.numberOfLines = 0
        payloadLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        payloadBox.backgroundColor = .tertiarySystemGroupedBackground
        payloadBox.layer.cornerRadius = 8
        payloadBox.embed(payloadLabel, insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        payloadBox.isHidden = true

        let stack = UIStackView(arrangedSubviews: [topRow, summaryLabel, payloadBox])
        stack.axis = .vertical
        stack.spacing = 8
        embed(stack, insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))

        guard payload != nil else { return }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggle)))
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(copyPayload(_:))))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func toggle() {
        UIView.animate(withDuration: 0.2) { self.payloadBox.isHidden.toggle() }
    }

    @objc private func copyPayload(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        UIPasteboard.general.string = payload
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
