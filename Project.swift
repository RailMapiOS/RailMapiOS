import ProjectDescription

let project = Project(
    name: "RailMapiOS",
    packages: [
            .package(path: "RailMapiOS/Packages/Helpers"),
            .package(url: "https://github.com/realm/SwiftLint", from: "0.58.2")
        ],
    targets: [
        .target(
            name: "RailMapiOS",
            destinations: .iOS,
            product: .app,
            bundleId: "com.railmap.RailMapiOS",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                    "NSContactsUsageDescription": "This app requires access to your contacts to display profile information."
                ]
            ),
            sources: ["RailMapiOS/Sources/**"],
            resources: ["RailMapiOS/Resources/**"],
            entitlements: "Config/RailMapiOSDebug.entitlements",
            dependencies: [
                .package(product: "Helpers"),
                .package(product: "SwiftLintBuildToolPlugin", type: .plugin)
            ],
            settings: .settings(base: [:], configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:])
            ]),
            coreDataModels: [
                .coreDataModel("CoreData/RailMap.xcdatamodeld")
            ]
        ),
        .target(
            name: "RailMapiOSTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.railmap.RailMapiOSTests",
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
            infoPlist: .default,
            sources: ["RailMapiOS/Tests/UITests/**"],
//            resources: [],
            dependencies: [
                .target(name: "RailMapiOS"),
                .package(product: "Helpers"),
                .sdk(name: "XCTest.framework", type: .framework),
                .sdk(name: "UIKit.framework", type: .framework),
            ]
        )

    ],
    resourceSynthesizers: .default //+ [.coreData()]
)
