// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sightline-AI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Sightline-AI",
            targets: ["Sightline-AI"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Sightline-AI",
            dependencies: [],
            path: "Sightline-AI",
            exclude: [
                "Info.plist",
                "Sightline_AI.entitlements",
                "Assets.xcassets",
                "Resources",
                "Documentation",
                "Adapters",
                "Backend",
                "Config",
                "Constants",
                "Core",
                "Extensions",
                "Features",
                "Helpers",
                "Managers",
                "Middleware",
                "Protocols",
                "Services",
                "Styles",
                "Tests",
                "Transformers",
                "UI",
                "Validators"
            ],
            sources: [
                "Sightline_AIApp.swift",
                "ContentView.swift"
            ]
        ),
        .testTarget(
            name: "Sightline-AITests",
            dependencies: ["Sightline-AI"],
            path: "Sightline-AITests"
        )
    ]
)