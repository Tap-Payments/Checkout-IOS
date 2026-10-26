// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Checkout-IOS",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Checkout-IOS",
            targets: ["Checkout-IOS"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/huri000/SwiftEntryKit.git", from: "1.0.0"),
        .package(url: "https://github.com/Tap-Payments/SharedDataModels-iOS.git", from: "0.0.1"),
        .package(url: "https://github.com/Tap-Payments/TapCardScannerWebWrapper-iOS.git", exact: "0.0.6"),
        .package(url: "https://github.com/Tap-Payments/TapFontKit-iOS.git", from: "0.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Checkout-IOS",
            dependencies: ["SwiftEntryKit",
                           "SharedDataModels-iOS",
                           "TapFontKit-iOS",
                           "TapCardScannerWebWrapper-iOS"],
            resources: [.process("Resources/TapCheckoutMedia.xcassets")],
            swiftSettings: [
                .define("SPM")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

