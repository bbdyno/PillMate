// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "SDWebImage": .framework,
            "SDWebImageSwiftUI": .framework
        ]
    )
#endif

let package = Package(
    name: "PillMate",
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.19.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.1.0")
    ]
)
