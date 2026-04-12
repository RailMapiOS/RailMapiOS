import ProjectDescription

let project = Project(
    name: "RailMapiOS",
    packages: [
            .package(path: "RailMapiOS/Packages/Helpers"),
            .package(url: "https://github.com/AliSoftware/OHHTTPStubs", .upToNextMinor(from: "9.1.0")),
            .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5")
        ],
    targets: [
        .target(
            name: "RailMapiOS",
            destinations: .iOS,
            product: .app,
            bundleId: "com.railmap.RailMapiOS",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                    "NSContactsUsageDescription": "This app requires access to your contacts to display profile information."
                ]
            ),
            sources: ["RailMapiOS/Sources/**", "SwiftData/**"],
            resources: ["RailMapiOS/Resources/**"],
            entitlements: "Config/RailMapiOSDebug.entitlements",
            dependencies: [
                .package(product: "Helpers"),
                .package(product: "OHHTTPStubs"),
                .package(product: "OHHTTPStubsSwift"),
                .package(product: "ComposableArchitecture")
            ],
            settings: .settings(base: [
                "SWIFT_VERSION": "5"
            ], configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:])
            ]),
            coreDataModels: []
        ),
        .target(
            name: "RailMapiOSTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.railmap.RailMapiOSTests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["RailMapiOS/Tests/UnitTests/**"],
            resources: [],
            dependencies: [.target(name: "RailMapiOS"), .package(product: "Helpers")]
        ),
        .target(
            name: "RailMapiOSUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.railmap.RailMapiOSUITests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["RailMapiOS/Tests/UITests/**"],
//            resources: [],
            dependencies: [
                .target(name: "RailMapiOS"),
                .package(product: "Helpers"),
                .package(product: "OHHTTPStubs"),
                .package(product: "OHHTTPStubsSwift")
            ]
        )

    ],
    resourceSynthesizers: .default //+ [.coreData()]
)
