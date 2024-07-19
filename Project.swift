import ProjectDescription

let project = Project(
    name: "RailMapiOS",
    targets: [
        .target(
            name: "RailMapiOS",
            destinations: .iOS,
            product: .app,
            bundleId: "com.railmap.RailMapiOS",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                ]
            ),
            sources: ["RailMapiOS/Sources/**"],
            resources: ["RailMapiOS/Resources/**"],
            dependencies: [],
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
            sources: ["RailMapiOS/Tests/**"],
            resources: [],
            dependencies: [.target(name: "RailMapiOS")]
        ),
        .target(
            name: "RailMapiOSUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.railmap.RailMapiOSUITests",
            infoPlist: .default,
            sources: ["RailMapiOS/Tests/**"],
            resources: [],
            dependencies: [.target(name: "RailMapiOS")]
        ),
    ],
    resourceSynthesizers: .default //+ [.coreData()]
)
