// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mumbler",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Mumbler",
            path: "Sources/Mumbler",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
