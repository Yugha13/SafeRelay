// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SafeRelay",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SafeRelay",
            targets: ["SafeRelay"]
        ),
    ],
    dependencies:[
        .package(path: "localPackages/Arti"),
        .package(path: "localPackages/BitLogger"),
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1")
    ],
    targets: [
        .executableTarget(
            name: "SafeRelay",
            dependencies: [
                .product(name: "P256K", package: "swift-secp256k1"),
                .product(name: "BitLogger", package: "BitLogger"),
                .product(name: "Tor", package: "Arti")
            ],
            path: "SafeRelay",
            exclude: [
                "Info.plist",
                "Assets.xcassets",
                "SafeRelay.entitlements",
                "SafeRelay-macOS.entitlements",
                "LaunchScreen.storyboard",
                "ViewModels/Extensions/README.md"
            ],
            resources: [
                .process("Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "SafeRelayTests",
            dependencies: ["SafeRelay"],
            path: "SafeRelayTests",
            exclude: [
                "Info.plist",
                "README.md"
            ],
            resources: [
                .process("Localization"),
                .process("Noise")
            ]
        )
    ]
)
