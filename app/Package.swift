// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Focus",
    platforms: [.macOS(.v13)],
    targets: [
        // Logic without UI, so it can be unit tested
        .target(name: "FocusCore"),
        .executableTarget(name: "Focus", dependencies: ["FocusCore"]),
        .testTarget(name: "FocusCoreTests", dependencies: ["FocusCore"]),
    ]
)
