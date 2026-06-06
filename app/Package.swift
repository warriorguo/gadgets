// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GadgetsApp",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "GadgetsApp",
            path: "Sources/GadgetsApp"
        )
    ]
)
