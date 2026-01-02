// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BlueNapkin",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BlueNapkin",
            targets: ["BlueNapkin"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BlueNapkin",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "BlueNapkinTests",
            dependencies: ["BlueNapkin"],
            path: "Tests"
        )
    ]
)
