// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "socketwebify",
    products: [
        .library(
            name: "WebTunnel",
            targets: ["WebTunnel"]
        ),
        .executable(
            name: "socketwebify",
            targets: ["SocketWebify"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "0.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.9.5"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "SocketWebify",
            dependencies: [
                "WebTunnel",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "WebTunnel",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
    ]
)
