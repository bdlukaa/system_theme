// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "system_theme",
    platforms: [
        .iOS("13")
    ],
    products: [
        .library(name: "system-theme", targets: ["system_theme"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "system_theme",
            dependencies: [],
            resources: [
            ]
        )
    ]
)
