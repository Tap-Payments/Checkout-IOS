//
//  SettingsViewController.swift
//  CocoaPodsExample
//
//  A form with every input of the Tap web demo, grouped like its steps (SDK / User / Card / Order /
//  Transaction). Every change is saved to UserDefaults immediately; "Show configuration JSON" displays
//  exactly what Start Checkout will pass to the SDK.
//

import UIKit

// MARK: - Form model

/// A value offered by a choice row: `value` goes into the configuration, `title` is shown to the user.
private struct Option {
    let value: String
    let title: String

    init(_ value: String, title: String? = nil) {
        self.value = value
        self.title = title ?? value
    }
}

private enum Options {
    static let currencies = ["KWD", "BHD", "SAR", "AED", "OMR", "EGP", "GBP", "USD", "EUR"].map { Option($0) }
    static let supportedCurrencies = (["ALL", "AUTO"] + ["KWD", "BHD", "SAR", "AED", "OMR", "EGP", "GBP", "USD", "EUR"]).map { Option($0) }
    static let paymentTypes = ["ALL", "WEB", "CARD", "DEVICE"].map { Option($0) }
    static let paymentMethods = ["ALL", "AMERICAN_EXPRESS", "APPLE_PAY", "BENEFIT", "BENEFITPAY", "CAREEMPAY", "FAWRY",
                                 "GOOGLE_PAY", "KNET", "MADA", "MASTERCARD", "MEEZA", "OMANNET", "PAYPAL", "POST_PAY",
                                 "NAPS", "STC_PAY", "TABBY", "VISA"].map { Option($0) }
    static let languages = [Option("auto"), Option("en"), Option("ar")]
    static let regions = ["LOCAL", "REGIONAL", "GLOBAL"].map { Option($0) }
    static let supportedPaymentTypes = ["CARD", "DEVICE_WALLET", "EXPRESS_CHECKOUT_WALLET", "PASS_THRU_WALLET",
                                        "STORED_VALUE_WALLET", "CASH_WALLET", "BNPL"].map { Option($0) }
    static let schemes = ["BENEFIT", "VISA", "AMEX", "MASTERCARD", "MADA", "MEEZA", "OMANNET"].map { Option($0) }
    /// ISO 3166-1 alpha-2 codes, titled with the country name.
    static let countries: [Option] = Locale.isoRegionCodes.compactMap { code in
        Locale.current.localizedString(forRegionCode: code).map { Option(code, title: "\(code) - \($0)") }
    }.sorted { $0.value < $1.value }

    static let fundingSources = [Option("all"), Option("credit"), Option("debit")]
    static let saveCardOptions = [Option("all"), Option("merchant"), Option("tap"), Option("none")]
    static let discountTypes = [Option("F", title: "Fixed amount"), Option("P", title: "Percentage")]
    static let modes = [Option("charge", title: "Charge"), Option("authorize", title: "Authorize")]
    static let themes = [Option("light"), Option("dark"), Option("light_mono"), Option("dark_colored"), Option("auto")]
    static let checkoutModes = [Option("popup"), Option("page")]
    static let authorizeTypes = [Option("CAPTURE"), Option("VOID")]
    static let agreementTypes = [Option("SCHEDULED"), Option("UNSCHEDULED")]
    static let amountVariabilities = [Option("FIXED"), Option("VARIABLE")]
    static let numbersOfPayments = [Option("Defined"), Option("Undefined")]
    static let airline = [Option("", title: "Not set (sent empty)"), Option("yes", title: "Yes"), Option("no", title: "No")]
}

private enum FormAction {
    case addItem
    case removeItem(Int)
    case showJSON
    case reset
}

private struct Row {
    typealias Path<Value> = WritableKeyPath<CheckoutSettings, Value>

    enum Kind {
        case text(Path<String>, keyboard: UIKeyboardType)
        case decimal(Path<Double>)
        case integer(Path<Int>)
        case toggle(Path<Bool>)
        case choice(Path<String>, [Option])
        case multiChoice(Path<[String]>, [Option])
        case info(String)
        case button(FormAction, destructive: Bool)
        case disclosure(FormAction)
    }

    let title: String
    let kind: Kind
}

private struct Section {
    let title: String
    var footer: String?
    let rows: [Row]
}

// MARK: - Settings screen

final class SettingsViewController: UITableViewController {

    private var settings = CheckoutSettings.load() {
        didSet { settings.save() }
    }

    private var sections: [Section] = []

    init() {
        super.init(style: .insetGrouped)
        title = "Settings"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .interactive
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: TextFieldCell.reuseIdentifier)
        tableView.register(SwitchCell.self, forCellReuseIdentifier: SwitchCell.reuseIdentifier)
        tableView.register(ValueCell.self, forCellReuseIdentifier: ValueCell.reuseIdentifier)
        rebuildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Coming back from a picker: its changes were saved through `settings` already.
        rebuildSections()
        tableView.reloadData()
    }

    // MARK: Sections (the form follows the web demo's wizard)

    /// Rebuilt after every change that can show or hide rows (mode, agreement, airline, items...).
    private func rebuildSections() {
        sections = [sdkSection, userSection, cardSection, orderSection, transactionSection]
    }

    private var sdkSection: Section {
        Section(title: "SDK Configuration", footer: "Defaults to the key in Keys.swift. Under each public key there can be several merchant ids; use the one that belongs to it.", rows: [
            Row(title: "Public Key", kind: .text(\.publicKey, keyboard: .asciiCapable)),
            Row(title: "Merchant Id", kind: .text(\.merchantId, keyboard: .asciiCapable)),
            Row(title: "Supported Currencies", kind: .multiChoice(\.supportedCurrencies, Options.supportedCurrencies)),
            Row(title: "Payment Type", kind: .choice(\.paymentType, Options.paymentTypes)),
            Row(title: "Supported Payment Methods", kind: .multiChoice(\.supportedPaymentMethods, Options.paymentMethods)),
            Row(title: "Selected Currency", kind: .choice(\.selectedCurrency, Options.currencies)),
            Row(title: "Language", kind: .choice(\.language, Options.languages)),
            Row(title: "Supported Regions", kind: .multiChoice(\.supportedRegions, Options.regions)),
            Row(title: "Supported Countries", kind: .multiChoice(\.supportedCountries, Options.countries)),
            Row(title: "Supported Payment Types", kind: .multiChoice(\.supportedPaymentTypes, Options.supportedPaymentTypes)),
            Row(title: "Supported Schemes", kind: .multiChoice(\.supportedSchemes, Options.schemes)),
        ])
    }

    private var userSection: Section {
        Section(title: "User Configuration", rows: [
            Row(title: "Customer ID", kind: .text(\.customerId, keyboard: .asciiCapable)),
            Row(title: "First Name", kind: .text(\.firstName, keyboard: .default)),
            Row(title: "Last Name", kind: .text(\.lastName, keyboard: .default)),
            Row(title: "Customer E-mail", kind: .text(\.email, keyboard: .emailAddress)),
            Row(title: "Customer Country Code", kind: .text(\.countryCode, keyboard: .numberPad)),
            Row(title: "Customer phone number", kind: .text(\.phoneNumber, keyboard: .phonePad)),
        ])
    }

    private var cardSection: Section {
        Section(title: "Card Configuration", rows: [
            Row(title: "Show Brands", kind: .toggle(\.showBrands)),
            Row(title: "Show Loading State", kind: .toggle(\.showLoadingState)),
            Row(title: "Collect Card Holder Name", kind: .toggle(\.collectHolderName)),
            Row(title: "PreLoad CardName", kind: .text(\.preLoadCardName, keyboard: .default)),
            Row(title: "CardName Editable", kind: .toggle(\.cardNameEditable)),
            Row(title: "Card Funding Source", kind: .choice(\.cardFundingSource, Options.fundingSources)),
            Row(title: "Save Card Options", kind: .choice(\.saveCardOption, Options.saveCardOptions)),
            Row(title: "Force LTR", kind: .toggle(\.forceLtr)),
            Row(title: "Card Scanner (iOS only)", kind: .toggle(\.cardScanner)),
        ])
    }

    private var orderSection: Section {
        var rows = [
            Row(title: "Order ID", kind: .text(\.orderId, keyboard: .asciiCapable)),
            Row(title: "Order discount type", kind: .choice(\.discountType, Options.discountTypes)),
            Row(title: "Order discount value", kind: .decimal(\.discountValue)),
        ]
        for index in settings.items.indices {
            let number = index + 1
            rows += [
                Row(title: "Order \(number) Name", kind: .text(\.items[index].name, keyboard: .default)),
                Row(title: "Order \(number) Description", kind: .text(\.items[index].description, keyboard: .default)),
                Row(title: "Order \(number) Quantity", kind: .integer(\.items[index].quantity)),
                Row(title: "Order \(number) Amount", kind: .decimal(\.items[index].amount)),
            ]
            // The web demo needs at least one item.
            if settings.items.count > 1 {
                rows.append(Row(title: "Remove item \(number)", kind: .button(.removeItem(index), destructive: true)))
            }
        }
        rows.append(Row(title: "Add New Item", kind: .button(.addItem, destructive: false)))
        rows.append(Row(title: "Total to pay", kind: .info("\(settings.totalAmount.displayString) \(settings.selectedCurrency)")))
        return Section(title: "Order Configuration", footer: "Total = items minus the discount (1 if the result is 0 or less).", rows: rows)
    }

    private var transactionSection: Section {
        var rows = [Row(title: "Transaction Mode", kind: .choice(\.mode, Options.modes))]
        if settings.mode == "authorize" {
            rows.append(Row(title: "Authorize Type", kind: .choice(\.authorizeType, Options.authorizeTypes)))
        }
        rows += [
            Row(title: "Theme", kind: .choice(\.theme, Options.themes)),
            Row(title: "Checkout Mode", kind: .choice(\.checkoutMode, Options.checkoutModes)),
            Row(title: "3D Secure", kind: .toggle(\.threeDSecure)),
            Row(title: "Hashstring", kind: .text(\.hashString, keyboard: .asciiCapable)),
            Row(title: "Agreed payment", kind: .toggle(\.agreedPayment)),
        ]
        if settings.agreedPayment {
            rows.append(Row(title: "Agreement Type", kind: .choice(\.agreementType, Options.agreementTypes)))
            if settings.agreementType == "SCHEDULED" {
                rows.append(Row(title: "Amount Variability", kind: .choice(\.amountVariability, Options.amountVariabilities)))
                rows.append(Row(title: "Number of payments", kind: .choice(\.numberOfPayments, Options.numbersOfPayments)))
                if settings.numberOfPayments == "Defined" {
                    rows.append(Row(title: "Count", kind: .integer(\.paymentCount)))
                }
            }
            rows += [
                Row(title: "Subscription Name", kind: .text(\.subscriptionName, keyboard: .default)),
                Row(title: "Subscription Description", kind: .text(\.subscriptionDescription, keyboard: .default)),
                Row(title: "Billing Agreement", kind: .text(\.billingAgreement, keyboard: .default)),
            ]
        }
        rows.append(Row(title: "Airline", kind: .choice(\.airline, Options.airline)))
        if settings.airline == "yes" {
            rows.append(Row(title: "Booking Reference Number", kind: .text(\.bookingReference, keyboard: .asciiCapable)))
        }
        return Section(title: "Transaction Configuration", rows: rows)
    }

    // MARK: Table view

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count + 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section < sections.count ? sections[section].rows.count : 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section < sections.count ? sections[section].title : "Tools"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section < sections.count ? sections[section].footer : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // The last section holds the two tools rows.
        if indexPath.section == sections.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath) as! ValueCell
            if indexPath.row == 0 {
                cell.configure(title: "Show configuration JSON", detail: nil, style: .disclosure)
            } else {
                cell.configure(title: "Reset to defaults", detail: nil, style: .destructive)
            }
            return cell
        }

        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case .text(let path, let keyboard):
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.reuseIdentifier, for: indexPath) as! TextFieldCell
            cell.configure(title: row.title, text: settings[keyPath: path], keyboard: keyboard) { [weak self] in
                self?.settings[keyPath: path] = $0
            }
            return cell

        case .decimal(let path):
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.reuseIdentifier, for: indexPath) as! TextFieldCell
            cell.configure(title: row.title, text: settings[keyPath: path].displayString, keyboard: .decimalPad) { [weak self] in
                self?.settings[keyPath: path] = Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0
                self?.refreshTotal()
            }
            return cell

        case .integer(let path):
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.reuseIdentifier, for: indexPath) as! TextFieldCell
            cell.configure(title: row.title, text: String(settings[keyPath: path]), keyboard: .numberPad) { [weak self] in
                self?.settings[keyPath: path] = Int($0) ?? 0
                self?.refreshTotal()
            }
            return cell

        case .toggle(let path):
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.reuseIdentifier, for: indexPath) as! SwitchCell
            cell.configure(title: row.title, isOn: settings[keyPath: path]) { [weak self] isOn in
                self?.settings[keyPath: path] = isOn
                // Some switches show or hide other rows; rebuild once the switch animation is done.
                DispatchQueue.main.async { self?.rebuildAndReload() }
            }
            return cell

        case .choice(let path, let options):
            let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath) as! ValueCell
            let selected = options.first { $0.value == settings[keyPath: path] }
            cell.configure(title: row.title, detail: selected?.title ?? settings[keyPath: path], style: .disclosure)
            return cell

        case .multiChoice(let path, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath) as! ValueCell
            let selected = settings[keyPath: path]
            let detail = selected.isEmpty ? "None" : (selected.count <= 2 ? selected.joined(separator: ", ") : "\(selected.count) selected")
            cell.configure(title: row.title, detail: detail, style: .disclosure)
            return cell

        case .info(let value):
            let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath) as! ValueCell
            cell.configure(title: row.title, detail: value, style: .plain)
            return cell

        case .button(_, let destructive):
            let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath) as! ValueCell
            cell.configure(title: row.title, detail: nil, style: destructive ? .destructive : .action)
            return cell

        case .disclosure:
            let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath) as! ValueCell
            cell.configure(title: row.title, detail: nil, style: .disclosure)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == sections.count {
            perform(indexPath.row == 0 ? .showJSON : .reset)
            return
        }

        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case .text, .decimal, .integer:
            (tableView.cellForRow(at: indexPath) as? TextFieldCell)?.focus()

        case .choice(let path, let options):
            let picker = OptionPickerViewController(title: row.title, options: options, selection: [settings[keyPath: path]], allowsMultiple: false) { [weak self] in
                self?.settings[keyPath: path] = $0.first ?? ""
            }
            navigationController?.pushViewController(picker, animated: true)

        case .multiChoice(let path, let options):
            let picker = OptionPickerViewController(title: row.title, options: options, selection: settings[keyPath: path], allowsMultiple: true) { [weak self] in
                self?.settings[keyPath: path] = $0
            }
            navigationController?.pushViewController(picker, animated: true)

        case .button(let action, _), .disclosure(let action):
            perform(action)

        case .toggle, .info:
            break
        }
    }

    // MARK: Actions

    private func perform(_ action: FormAction) {
        switch action {
        case .addItem:
            // Same values the web demo gives a new item.
            settings.items.append(CheckoutSettings.OrderItem(name: "order item name", description: "order item description", quantity: 1, amount: 10))
            rebuildAndReload()
        case .removeItem(let index):
            guard settings.items.count > 1 else { return }
            settings.items.remove(at: index)
            rebuildAndReload()
        case .showJSON:
            navigationController?.pushViewController(ConfigurationJSONViewController(configuration: settings.makeConfiguration()), animated: true)
        case .reset:
            let alert = UIAlertController(title: "Reset to defaults?", message: "All settings go back to the web demo defaults.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
                CheckoutSettings.reset()
                self?.settings = CheckoutSettings.load()
                self?.rebuildAndReload()
            })
            present(alert, animated: true)
        }
    }

    private func rebuildAndReload() {
        view.endEditing(true)
        rebuildSections()
        tableView.reloadData()
    }

    /// Updates the read-only "Total to pay" row while an amount, quantity or discount is typed.
    private func refreshTotal() {
        for (sectionIndex, section) in sections.enumerated() {
            for (rowIndex, row) in section.rows.enumerated() {
                guard case .info = row.kind else { continue }
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                (tableView.cellForRow(at: indexPath) as? ValueCell)?
                    .configure(title: row.title, detail: "\(settings.totalAmount.displayString) \(settings.selectedCurrency)", style: .plain)
            }
        }
    }
}

// MARK: - Option picker (single and multiple choice)

private final class OptionPickerViewController: UITableViewController {
    private let options: [Option]
    private var selection: [String]
    private let allowsMultiple: Bool
    private let onChange: ([String]) -> Void

    init(title: String, options: [Option], selection: [String], allowsMultiple: Bool, onChange: @escaping ([String]) -> Void) {
        self.options = options
        self.selection = selection
        self.allowsMultiple = allowsMultiple
        self.onChange = onChange
        super.init(style: .insetGrouped)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { options.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let option = options[indexPath.row]
        cell.textLabel?.text = option.title
        cell.accessoryType = selection.contains(option.value) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let value = options[indexPath.row].value
        if allowsMultiple {
            if let index = selection.firstIndex(of: value) { selection.remove(at: index) } else { selection.append(value) }
            // Keep the saved list in the order the options are listed in.
            selection = options.map(\.value).filter(selection.contains)
            onChange(selection)
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            selection = [value]
            onChange(selection)
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - Configuration JSON viewer

private final class ConfigurationJSONViewController: UIViewController {
    private let configuration: [String: Any]

    init(configuration: [String: Any]) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        title = "Configuration JSON"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let textView = UITextView(frame: view.bounds)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.text = prettyJSON
        view.addSubview(textView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Copy", style: .plain, target: self, action: #selector(copyJSON))
    }

    private var prettyJSON: String {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? JSONSerialization.data(withJSONObject: configuration, options: options),
              let string = String(data: data, encoding: .utf8) else { return "Could not encode the configuration." }
        return string
    }

    @objc private func copyJSON() {
        UIPasteboard.general.string = prettyJSON
    }
}

// MARK: - Cells

private final class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    static let reuseIdentifier = "TextFieldCell"

    private let titleLabel = UILabel()
    private let textField = UITextField()
    private var onChange: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        textField.textAlignment = .right
        textField.textColor = .secondaryLabel
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearButtonMode = .never
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        [titleLabel, textField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: margins.topAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -4),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: margins.widthAnchor, multiplier: 0.6),
            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(title: String, text: String, keyboard: UIKeyboardType, onChange: @escaping (String) -> Void) {
        titleLabel.text = title
        textField.text = text
        textField.keyboardType = keyboard
        self.onChange = onChange
    }

    func focus() { textField.becomeFirstResponder() }

    @objc private func editingChanged() { onChange?(textField.text ?? "") }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

private final class SwitchCell: UITableViewCell {
    static let reuseIdentifier = "SwitchCell"

    private let toggle = UISwitch()
    private var onChange: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        textLabel?.numberOfLines = 0
        accessoryView = toggle
        toggle.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) {
        textLabel?.text = title
        toggle.isOn = isOn
        self.onChange = onChange
    }

    @objc private func valueChanged() { onChange?(toggle.isOn) }
}

/// Title on the left, optional value on the right (UITableViewCell's `.value1` style).
private final class ValueCell: UITableViewCell {
    static let reuseIdentifier = "ValueCell"

    enum Style { case plain, disclosure, action, destructive }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 0
        detailTextLabel?.numberOfLines = 0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(title: String, detail: String?, style: Style) {
        textLabel?.text = title
        detailTextLabel?.text = detail
        switch style {
        case .plain:
            textLabel?.textColor = .label
            accessoryType = .none
            selectionStyle = .none
        case .disclosure:
            textLabel?.textColor = .label
            accessoryType = .disclosureIndicator
            selectionStyle = .default
        case .action:
            textLabel?.textColor = .systemBlue
            accessoryType = .none
            selectionStyle = .default
        case .destructive:
            textLabel?.textColor = .systemRed
            accessoryType = .none
            selectionStyle = .default
        }
    }
}

// MARK: - Helpers

private extension Double {
    /// 0.1 -> "0.1", 10.0 -> "10" (no trailing ".0").
    var displayString: String {
        let text = String(self)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}
