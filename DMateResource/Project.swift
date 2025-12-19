import ProjectDescription

let project = Project(
    name: "DMateResource",
    targets: [
        .target(
            name: "DMateResource",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.bbdyno.app.doseMate.DMateResource",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: []
        )
    ]
)
