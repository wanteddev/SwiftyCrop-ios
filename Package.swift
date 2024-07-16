// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyCrop",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyCrop",
            targets: ["SwiftyCrop"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/wanteddev/montage-ios", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyCrop",
            dependencies: [
                .product(name: "Montage", package: "montage-ios")
            ],
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "SwiftyCropTests",
            dependencies: ["SwiftyCrop"])
    ]
)
