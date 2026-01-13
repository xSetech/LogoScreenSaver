// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LogoScreenSaver",
    platforms: [
        // Xcode target uses MACOSX_DEPLOYMENT_TARGET = 14.0
        .macOS(.v14)
    ],
    products: [
        // Core library (shared code)
        .library(
            name: "LogoScreenSaverCore",
            targets: ["LogoScreenSaverCore"]
        ),
        // Screen saver library
        .library(
            name: "LogoScreenSaver",
            targets: ["LogoScreenSaver"]
        ),
        // Test app executable
        .executable(
            name: "LogoScreenSaverApp",
            targets: ["LogoScreenSaverApp"]
        )
    ],
    targets: [
        // Core shared code (no ScreenSaver framework dependency)
        .target(
            name: "LogoScreenSaverCore",
            path: "Core",
            resources: [
                .copy("Resources")
            ]
        ),

        // Screen saver target (depends on Core)
        .target(
            name: "LogoScreenSaver",
            dependencies: ["LogoScreenSaverCore"],
            path: "ScreenSaver",
            exclude: [
                "Info.plist",
                "thumbnail.png",
                "thumbnail@2x.png",
                "AppIcon.icns"
            ]
        ),

        // App executable target (depends on Core and ScreenSaver for ConfigureSheetController)
        .executableTarget(
            name: "LogoScreenSaverApp",
            dependencies: [
                "LogoScreenSaverCore",
                "LogoScreenSaver"
            ],
            path: "App",
            exclude: [
                "Info.plist",
                "LogoScreenSaverApp.entitlements",
                "AppIcon.icns"
            ]
        ),

        // Tests (test Core functionality)
        .testTarget(
            name: "LogoScreenSaverTests",
            dependencies: ["LogoScreenSaverCore"],
            path: "Tests/LogoScreenSaverTests",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
