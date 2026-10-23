// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyGlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KeyGlow", targets: ["KeyGlow"])
    ],
    targets: [
        .executableTarget(
            name: "KeyGlow",
            path: "Sources"
        )
    ]
)
