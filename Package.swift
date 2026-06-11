// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Macban",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Macban", targets: ["Macban"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "MacbanCore"),
        .executableTarget(
            name: "Macban",
            dependencies: ["MacbanCore"]
        ),
        .testTarget(
            name: "MacbanCoreTests",
            dependencies: ["MacbanCore"]
        ),
    ]
)
