import ProjectDescription

let project = Project(
    name: "RailMapiOS",
    // Source language is English. The String Catalog at
    // `RailMapiOS/Resources/Localizable.xcstrings` lists target languages —
    // Xcode reads this list and expects translations for each.
    options: .options(developmentRegion: "en"),
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
                    // Was `UILaunchStoryboardName: "LaunchScreen.storyboard"`, which
                    // upload rejected with ITMS-90476: the key takes the storyboard's
                    // base name, so the validator looked for
                    // `LaunchScreen.storyboard.storyboardc` in the bundle.
                    // The storyboard only painted `systemBackgroundColor`, so the
                    // iOS 14+ dictionary form reproduces it exactly, without a file.
                    "UILaunchScreen": .dictionary([:]),
                    // Required at the ROOT of Info.plist by App Store validation
                    // (ITMS-90713). `actool` only emits it nested under
                    // CFBundleIcons/CFBundlePrimaryIcon; Xcode adds the root-level
                    // copy only when it generates the Info.plist itself, which it
                    // does not here — Tuist supplies an explicit INFOPLIST_FILE.
                    "CFBundleIconName": "AppIcon",
                    "NSContactsUsageDescription": "This app requires access to your contacts to display profile information.",
                    // Read by `APIConfiguration.baseURL`. The value comes from the
                    // per-configuration build setting defined below.
                    "RAILMAP_API_URL": "$(RAILMAP_API_URL)",
                    // The app only talks HTTPS through URLSession, which falls under
                    // the standard export-compliance exemption. Declaring it here
                    // stops App Store Connect asking on every single upload.
                    "ITSAppUsesNonExemptEncryption": false
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
                "SWIFT_VERSION": "5",
                // Pinned here so the choice survives `tuist generate`, which
                // rewrites the project. Recovered from commit e614320.
                "DEVELOPMENT_TEAM": "MZ3E779E6C",
                "CODE_SIGN_STYLE": "Automatic"
            ], configurations: [
                // Debug talks to the backend running on the Mac (simulator shares
                // the host loopback). Release/TestFlight goes through the
                // Cloudflare Tunnel in front of the Raspberry Pi.
                .debug(name: "Debug", settings: [
                    "RAILMAP_API_URL": "http://127.0.0.1:8080"
                ]),
                .release(name: "Release", settings: [
                    "RAILMAP_API_URL": "https://api.jeremiepatot.fr",
                    // The target-level `entitlements:` above is the Debug file,
                    // which carries `aps-environment: development` — rejected when
                    // exporting against an App Store distribution profile.
                    "CODE_SIGN_ENTITLEMENTS": "Config/RailMapiOS.entitlements"
                ])
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
