import ProjectDescription

let project = Project(
    name: "Timer",
    targets: [
        .target(
            name: "Timer",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Timer",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                ]
            ),
            sources: ["Timer/Sources/**"],
            resources: ["Timer/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "TimerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.TimerTests",
            infoPlist: .default,
            sources: ["Timer/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Timer")]
        ),
    ]
)
