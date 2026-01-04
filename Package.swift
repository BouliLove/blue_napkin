// swift-tools-version: 5.9
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
    targets: [
        .executableTarget(
            name: "BlueNapkin",
            path: "BlueNapkin",
            exclude: ["Info.plist", "Assets.xcassets"],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
