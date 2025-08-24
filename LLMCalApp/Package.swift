// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LLMCalApp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "LLMCalApp",
            targets: ["LLMCalApp"]),
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "LLMCalApp",
            dependencies: [],
            resources: [
                .process("Resources"),
                .copy("calendar.sh")
            ],
            swiftSettings: [
                .define("ENABLE_BUNDLE_ACCESS")
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
