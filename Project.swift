import ProjectDescription

let project = Project(
    name: "RailMapiOS",
    packages: [
            .package(path: "RailMapiOS/Packages/Helpers"),
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
            scripts: [
                .pre(script: """
                if which swiftlint > /dev/null; then
                  swiftlint
                else
                  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
                fi
                """, name: "Run SwiftLint"),
                .pre(script: """
                mkdir -p "${SRCROOT}/RailMapiOS/Sources/Generated"
                if [ ! -f "${SRCROOT}/RailMapiOS/Sources/Generated/Strings.swift" ]; then
                  echo "// Generated file\nimport Foundation\n\n// Add your string extensions here" > "${SRCROOT}/RailMapiOS/Sources/Generated/Strings.swift"
                fi
                """, name: "Create Generated Directory")
            ], dependencies: [
                .package(product: "Helpers"),
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
