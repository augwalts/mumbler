// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mumbler",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Mumbler",
            path: "Sources/Mumbler",
            exclude: ["Resources"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
