import ProjectDescription

// MARK: - Module Names
enum ModuleName: String {
    case designSystem = "DMateDesignSystem"
    case resource = "DMateResource"

    var targetName: String {
        return self.rawValue
    }

    var bundleId: String {
        return "com.bbdyno.app.doseMate.\(self.rawValue)"
    }

    var path: Path {
        return .relativeToRoot(self.rawValue)
    }
}

// MARK: - TargetDependency Extension
extension TargetDependency {
    static func module(_ module: ModuleName) -> TargetDependency {
        return .project(target: module.targetName, path: module.path)
    }
}

let project = Project(
    name: "DoseMate",
    targets: [
        .target(
            name: "DoseMate",
            destinations: .iOS,
            product: .app,
            bundleId: "com.bbdyno.app.doseMate",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDevelopmentRegion": "en",
                    "CFBundleLocalizations": ["en", "ko", "id", "zh-Hans", "ja"],
                    "CFBundleDisplayName": "복약 관리",
                    "ITSAppUsesNonExemptEncryption": false,
                    "NSCameraUsageDescription": "약물 사진을 촬영하여 등록할 수 있습니다.",
                    "NSFaceIDUsageDescription": "Face ID를 사용하여 앱에 빠르게 접근할 수 있습니다.",
                    "NSHealthShareUsageDescription": "건강 데이터를 읽어 복약 관리와 건강 지표 추적에 활용합니다.",
                    "NSHealthUpdateUsageDescription": "건강 데이터에 복약 기록과 건강 지표를 저장합니다.",
                    "NSPhotoLibraryUsageDescription": "약물 사진을 갤러리에서 선택할 수 있습니다.",
                    "NSUserNotificationsUsageDescription": "복약 시간에 알림을 보내 약 복용을 잊지 않도록 도와드립니다.",
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": true
                    ],
                    "UILaunchScreen": [:],
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "UISupportedInterfaceOrientations~ipad": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationPortraitUpsideDown",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "UIBackgroundModes": [
                        "fetch",
                        "processing",
                        "remote-notification"
                    ],
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": false
                    ]
                ]
            ),
            sources: ["DoseMate/**"],
            resources: ["DoseMate/**/*.{xcassets,strings,storyboard,xib,md}"],
            entitlements: .file(path: "DoseMate/Resources/DoseMate.entitlements"),
            dependencies: [
                .module(.designSystem),
                .module(.resource),
                .target(name: "DoseMateWidget"),
                .external(name: "SDWebImage"),
                .external(name: "SDWebImageSwiftUI")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Manual",
                    "CODE_SIGN_IDENTITY": "iPhone Developer: Taein Kim",
                    "DEVELOPMENT_TEAM": "4U62JZ6987",
                    "PROVISIONING_PROFILE_SPECIFIER": "DoseMate App Provisioning"
                ]
            )
        ),
        .target(
            name: "DoseMateWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.bbdyno.app.doseMate.widget",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                    ]
                ]
            ),
            sources: ["DoseMateWidget/**", "Derived/Sources/TuistStrings+DoseMate.swift"],
            resources: ["DoseMateWidget/**/*.xcassets"],
            entitlements: .file(path: "DoseMateWidget/DoseMateWidget.entitlements"),
            dependencies: [
                .module(.designSystem),
                .module(.resource)
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Manual",
                    "CODE_SIGN_IDENTITY": "iPhone Developer: Taein Kim",
                    "DEVELOPMENT_TEAM": "4U62JZ6987",
                    "PROVISIONING_PROFILE_SPECIFIER": "DoseMate WidgetExtension Provisioning"
                ]
            )
        ),
        .target(
            name: "DoseMateTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.bbdyno.app.doseMate.tests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["DoseMateTests/**"],
            dependencies: [
                .target(name: "DoseMate")
            ]
        ),
        .target(
            name: "DoseMateUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.bbdyno.app.doseMate.uitests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["DoseMateUITests/**"],
            dependencies: [
                .target(name: "DoseMate")
            ]
        )
    ]
)
