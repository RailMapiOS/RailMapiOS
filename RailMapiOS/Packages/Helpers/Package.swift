// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Helpers",
    // Bumped from default to match the host app's deployment target — required
    // for `String(localized:)` (iOS 15+) and `LocalizedStringResource` (iOS 16+).
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Helpers",
            targets: ["Helpers"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Helpers"),
        .testTarget(
            name: "HelpersTests",
            dependencies: ["Helpers"]
        ),
    ]
)
