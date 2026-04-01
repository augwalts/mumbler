// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mumbler",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "Mumbler",
            dependencies: ["HotKey"],
            path: "Sources/Mumbler",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
