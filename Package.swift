// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TimeTracker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TimeTracker", targets: ["TimeTracker"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "TimeTracker",
            dependencies: ["Yams", "HotKey"],
            path: "TimeTracker",
            exclude: ["Info.plist", "TimeTracker.entitlements"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
