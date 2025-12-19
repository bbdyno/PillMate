import ProjectDescription

let project = Project(
    name: "DMateDesignSystem",
    targets: [
        .target(
            name: "DMateDesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.bbdyno.app.doseMate.DMateDesignSystem",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: []
        )
    ]
)
