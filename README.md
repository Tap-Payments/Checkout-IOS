# Checkout-IOS

Tap Payments' iOS checkout SDK. Present a full Tap checkout sheet from your app, collect a card or local payment method, and get the result back through a small delegate.

![Platform](https://img.shields.io/badge/platform-iOS-blue)
![Swift Package Manager](https://img.shields.io/badge/SPM-supported-brightgreen)
![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-brightgreen)

- [Requirements](#requirements)
- [Installation](#installation)
- [Info.plist](#infoplist)
- [Quick start](#quick-start)
- [Callbacks](#callbacks)
- [Configuration reference](#configuration-reference)
- [Charge vs Authorize](#charge-vs-authorize)
- [Sandbox vs production](#sandbox-vs-production)
- [Example apps](#example-apps)
- [Troubleshooting](#troubleshooting)

## Requirements

| | Swift Package Manager | CocoaPods |
|---|---|---|
| Minimum iOS | 13.0 (as declared in `Package.swift`) | 15.0 |
| Xcode | Latest stable | Latest stable (Xcode 27 builds iOS 15+ only) |

> [!NOTE]
> Current release: **1.0.5**. Replace the version in the snippets below with the latest tag from the [releases page](https://github.com/Tap-Payments/Checkout-IOS/tags).

## Installation

### Swift Package Manager

In Xcode choose **File > Add Package Dependencies...** and enter:

```
https://github.com/Tap-Payments/Checkout-IOS.git
```

Select the `Checkout-IOS` product and add it to your app target. Or, in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Tap-Payments/Checkout-IOS.git", from: "1.0.5")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "Checkout-IOS", package: "Checkout-IOS")
    ])
]
```

Then import the module (note the underscore):

```swift
import Checkout_IOS
```

### CocoaPods

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'Checkout-IOS', '~> 1.0.5'
end
```

```bash
pod install
```

Open the generated `.xcworkspace`, not the `.xcodeproj`.

> [!TIP]
> On Xcode 27, some transitive pods still declare a minimum below iOS 15 and fail to build. Add this hook to the end of your Podfile (copied from [`CocoaPodsExample/Podfile`](CocoaPodsExample/Podfile)):
>
> ```ruby
> post_install do |installer|
>   installer.pods_project.targets.each do |target|
>     target.build_configurations.each do |config|
>       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
>     end
>   end
> end
> ```

## Info.plist

Add a camera usage description. It is required by the card scanner; without it iOS terminates the app when the scanner opens.

```xml
<key>NSCameraUsageDescription</key>
<string>Used to scan your card.</string>
```

## Quick start

1. Build a configuration dictionary.
2. Implement `CheckoutSDKDelegate`.
3. Call `CheckoutSDK().start(configurations:delegate:)`.

```swift
import UIKit
import Checkout_IOS

final class CheckoutViewController: UIViewController, CheckoutSDKDelegate {

    // CheckoutSDKDelegate: the controller the checkout sheet is presented from.
    var controller: UIViewController { self }

    @IBAction func payTapped(_ sender: Any) {
        let configurations: [String: Any] = [
            "gateway": ["publicKey": "pk_test_YOUR_PUBLIC_KEY"],
            "language": "en",
            "themeMode": "light",
            "paymentType": "ALL",
            "supportedPaymentMethods": "ALL",
            "supportedCurrencies": "ALL",
            "selectedCurrency": "KWD",
            "amount": 5,
            "customer": [
                "firstName": "Jane",
                "lastName": "Doe",
                "email": "jane@example.com",
                "phone": ["countryCode": "965", "number": "55567890"]
            ],
            "order": [
                "currency": "KWD",
                "amount": 5,
                "items": [
                    ["name": "Item", "description": "Item description",
                     "quantity": 1, "amount": 5, "currency": "KWD"]
                ]
            ],
            "transaction": [
                "mode": "charge",
                "charge": [
                    "saveCard": true,
                    "threeDSecure": true,
                    "redirect": ["url": "https://example.com/checkout/return"]
                ]
            ]
        ]

        CheckoutSDK().start(configurations: configurations, delegate: self)
    }

    // MARK: CheckoutSDKDelegate
    func onReady() { }
    func onChargeCreated(data: String) { print("charge created:", data) }
    func onSuccess(data: String) { print("success:", data) }
    func onError(data: String) { print("error:", data) }
    func onClose() { }
}
```

> [!IMPORTANT]
> The SDK keeps only a **weak** reference to the delegate. Make sure your app retains it (a view controller that stays on screen, as above, is fine). A temporary object will be deallocated and you will never receive callbacks.

> [!NOTE]
> `start` does not validate the configuration. Invalid or missing values are reported by the Tap backend inside the checkout sheet or through `onError`.

## Callbacks

All five methods of `CheckoutSDKDelegate` are required. The `data` argument is a **JSON string** produced by the checkout; parse it with `JSONSerialization` or `JSONDecoder`.

| Callback | Fires when | `data` | Sheet dismissed |
|---|---|---|---|
| `onReady()` | The checkout page finished loading and is ready for input. | none | No |
| `onChargeCreated(data:)` | A charge/authorization object was created. | JSON string | No |
| `onSuccess(data:)` | The checkout completed, including after a 3D Secure challenge. | JSON string (after 3DS: the charge id) | Yes, before the callback |
| `onError(data:)` | The checkout failed, a network step failed, or the camera permission was denied. | JSON string (some native errors are plain text) | Yes, before the callback |
| `onClose()` | The user closed the checkout. | none | Yes, before the callback |

> [!TIP]
> Treat `onSuccess` as "the flow finished" and confirm the final payment status on your server using the charge id from the payload.

## Configuration reference

The configuration is a `[String: Any]` dictionary that mirrors the Tap web checkout demo. Dotted paths mean nested dictionaries (`gateway.publicKey` is `["gateway": ["publicKey": ...]]`). Defaults are the values the example apps send, which match the web demo; "omit" means the key is not sent. The SDK reads only `gateway.publicKey` and `language` itself; everything else is forwarded to the Tap backend.

### SDK and gateway

| Key | Type | Values | Default |
|---|---|---|---|
| `gateway.publicKey` | String | Your Tap public key (`pk_test_...` / `pk_live_...`). Required. | none |
| `gateway.merchantId` | String | Merchant id associated with the key | omit |
| `hashString` | String | Hash generated on your server (see [Sandbox vs production](#sandbox-vs-production)) | `""` |
| `language` | String | `en`, `ar` | `en` |
| `themeMode` | String | `light`, `dark`, `light_mono`, `dark_colored` | `light` |
| `paymentType` | String | `ALL`, `WEB`, `CARD`, `DEVICE` | `ALL` |
| `supportedPaymentMethods` | String or [String] | `"ALL"` or any of `AMERICAN_EXPRESS`, `APPLE_PAY`, `BENEFIT`, `BENEFITPAY`, `CAREEMPAY`, `FAWRY`, `GOOGLE_PAY`, `KNET`, `MADA`, `MASTERCARD`, `MEEZA`, `OMANNET`, `PAYPAL`, `POST_PAY`, `NAPS`, `STC_PAY`, `TABBY`, `VISA` | `"ALL"` |
| `selectedCurrency` | String | `KWD`, `BHD`, `SAR`, `AED`, `OMR`, `EGP`, `GBP`, `USD`, `EUR` | `SAR` |
| `supportedCurrencies` | String or [String] | `"ALL"`, `"AUTO"`, or a list of currency codes | `"ALL"` |
| `supportedRegions` | [String] | `LOCAL`, `REGIONAL`, `GLOBAL` | omit |
| `supportedCountries` | [String] | ISO alpha-2 country codes | omit |
| `supportedPaymentTypes` | [String] | `CARD`, `DEVICE_WALLET`, `EXPRESS_CHECKOUT_WALLET`, `PASS_THRU_WALLET`, `STORED_VALUE_WALLET`, `CASH_WALLET`, `BNPL` | omit |
| `supportedSchemes` | [String] | `BENEFIT`, `VISA`, `AMEX`, `MASTERCARD`, `MADA`, `MEEZA`, `OMANNET` | omit |
| `isApplePayAvailableOnClient` | Bool | | `true` |
| `open` | Bool | Always `true` (the web SDK adds it too) | `true` |

### Customer

| Key | Type | Notes |
|---|---|---|
| `customer.id` | String | Existing Tap customer id. Omit if empty. |
| `customer.firstName` | String | Required. |
| `customer.lastName` | String | Required unless `customer.id` is set. |
| `customer.email` | String | |
| `customer.phone.countryCode` | String | For example `965`. |
| `customer.phone.number` | String | Digits and `+`, at least 8 characters. |

### Card options

| Key | Type | Values | Default |
|---|---|---|---|
| `cardOptions.showBrands` | Bool | | `true` |
| `cardOptions.showLoadingState` | Bool | | `false` |
| `cardOptions.collectHolderName` | Bool | | `true` |
| `cardOptions.preLoadCardName` | String | Pre-filled card holder name | `""` |
| `cardOptions.cardNameEditable` | Bool | | `true` |
| `cardOptions.cardFundingSource` | String | `all`, `credit`, `debit` | `all` |
| `cardOptions.saveCardOption` | String | `all`, `merchant`, `tap`, `none` | `all` |
| `cardOptions.forceLtr` | Bool | | `false` |
| `cardOptions.alternativeCardInputs.cardScanner` | Bool | Shows the native card scanner button. Needs `NSCameraUsageDescription`. | omit |

### Order

| Key | Type | Notes |
|---|---|---|
| `amount` | Number | Order total: sum of `amount * quantity` over items, minus the discount. Must be greater than 0. |
| `order.id` | String | Your order reference. Default `""`. |
| `order.currency` | String | Same as `selectedCurrency`. |
| `order.amount` | Number | Same value as top-level `amount`. |
| `order.items[]` | Array | At least one item. |
| `order.items[].name` | String | Min 2 characters. |
| `order.items[].description` | String | Min 2 characters. |
| `order.items[].quantity` | Number | Required. |
| `order.items[].amount` | Number | `>= 0`. |
| `order.items[].currency` | String | Same as `selectedCurrency`. |
| `order.discount.type` | String | `F` (fixed) or `P` (percentage). Send only when the value is greater than 0. |
| `order.discount.value` | Number | Discount value. |

### Transaction

| Key | Type | Values | Default |
|---|---|---|---|
| `transaction.mode` | String | `charge`, `authorize` | `charge` |
| `transaction.<mode>.threeDSecure` | Bool | | `true` |
| `transaction.<mode>.saveCard` | Bool | | `true` |
| `transaction.<mode>.redirect.url` | String | URL the 3D Secure / redirect flow returns to | none |
| `transaction.<mode>.auto.type` | String | `CAPTURE`, `VOID` (see [Charge vs Authorize](#charge-vs-authorize)) | `VOID` |
| `transaction.<mode>.auto.time` | Number | Hours before the automatic action | `100` |
| `transaction.<mode>.agreement.type` | String | `SCHEDULED`, `UNSCHEDULED` (recurring / saved agreements) | omit |
| `transaction.<mode>.agreement.amount_variability` | String | `FIXED`, `VARIABLE` (scheduled only) | `FIXED` |
| `transaction.<mode>.subscription.type` | String | `SCHEDULED` (not sent when the agreement type is `UNSCHEDULED`) | `SCHEDULED` |
| `transaction.<mode>.subscription.amount_variability` | String | `FIXED`, `VARIABLE` | `FIXED` |
| `transaction.<mode>.subscription.txn_count` | Number | Number of payments; `0` means undefined | `0` |
| `transaction.<mode>.airline.reference.booking` | String | Airline booking reference. `airline` is sent by default; leave it out to disable it. | `""` |

`<mode>` is the value of `transaction.mode`.

> [!NOTE]
> The SDK always forces `cardNFC` to `false` anywhere it appears in the configuration, so NFC card entry is not available.

## Charge vs Authorize

`transaction.mode` decides what the checkout creates:

- `charge`: payment is captured immediately.
- `authorize`: funds are reserved and captured or voided later.

The settings for the transaction live in a sub-object **named after the mode**: `transaction.charge` for charges, `transaction.authorize` for authorizations. The inner fields are identical; only the key name changes. Use exactly one.

For authorizations, `auto` controls what happens if you do nothing:

- `auto.type`: `CAPTURE` captures the authorization automatically, `VOID` releases it.
- `auto.time`: hours to wait before that automatic action is applied (`100` in the web demo).

**Charge**

```json
{
  "transaction": {
    "mode": "charge",
    "charge": {
      "saveCard": true,
      "threeDSecure": true,
      "redirect": { "url": "https://example.com/checkout/return" }
    }
  }
}
```

**Authorize**

```json
{
  "transaction": {
    "mode": "authorize",
    "authorize": {
      "saveCard": true,
      "threeDSecure": true,
      "auto": { "type": "VOID", "time": 100 },
      "redirect": { "url": "https://example.com/checkout/return" }
    }
  }
}
```

The SDK itself handles both modes the same way and fires the same callbacks. To capture or void an authorization manually, call the Tap API **from your server** using the authorization id returned in the callback payload. See [developers.tap.company](https://developers.tap.company).

## Sandbox vs production

| | Sandbox | Production |
|---|---|---|
| Public key | `pk_test_...` | `pk_live_...` |
| Money moves | No | Yes |

- Switch environments by changing `gateway.publicKey`. The Tap backend picks sandbox or production from the key.
- Use only your **public** key in the app. Never embed a secret key (`sk_...`) in a mobile binary.
- `hashString` must be generated on **your server** and passed to the app. Follow the [Tap documentation](https://developers.tap.company) for how to compute it; do not compute it with a secret key on the device.
- Keep keys out of source control: load them from build configuration or a remote config, not hard-coded literals in committed files.

## Example apps

Two minimal apps live in this repository.

| App | Integration | Run |
|---|---|---|
| [`SPMExample`](SPMExample) | Swift Package Manager | Open `SPMExample/SPMExample.xcodeproj` and run. |
| [`CocoaPodsExample`](CocoaPodsExample) | CocoaPods | `cd CocoaPodsExample && pod install`, then open `CocoaPodsExample.xcworkspace` and run. |

Both include a **Settings** screen that mirrors every input of the Tap web demo and a **Show configuration JSON** view that prints the exact dictionary passed to `start`.

Before running, open `Keys.swift` and replace the placeholder `YOUR_TAP_PUBLIC_KEY` with your own Tap public key. Keys are not committed to the repository.

**Sandbox test card (3D Secure)**

| Card number | Expiry | CVV |
|---|---|---|
| 4508 7500 1574 1019 | 01/39 | 100 |

## Troubleshooting

| Problem | Fix |
|---|---|
| CocoaPods build fails on Xcode 27 with an `IPHONEOS_DEPLOYMENT_TARGET` error | Set `platform :ios, '15.0'` and add the `post_install` hook from [Installation](#cocoapods). |
| App crashes when tapping the card scanner | Add `NSCameraUsageDescription` to Info.plist. |
| Camera permission denied | The checkout closes and `onError` fires with `{"error":"The user didn't approve accessing the camera."}`. Ask the user to enable the camera in Settings. |
| No callbacks arrive | Your delegate was deallocated. The SDK holds it weakly; retain it. |
| Blank sheet, nothing happens | Check connectivity and that `gateway.publicKey` is valid. |
| Sheet does not appear | Return a view controller that is currently on screen from `controller`; the sheet is presented from it. |
