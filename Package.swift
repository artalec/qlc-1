// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SunliteQLC",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SunliteQLC",
            path: "Sources/SunliteQLC"
        )
    ]
)
