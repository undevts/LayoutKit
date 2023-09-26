// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LayoutKit",
    products: [
        .library(
            name: "LayoutKit",
            targets: ["LayoutKit"]),
        .library(
            name: "AutoLayoutKit",
            targets: ["AutoLayoutKit"]),
        .library(
            name: "FlexLayoutKit",
            targets: ["FlexLayoutKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/undevts/CoreSwift.git", from: "0.1.3"),
    ],
    targets: [
        .target(
            name: "LayoutKit",
            dependencies: [
                "AutoLayoutKit",
                "FlexLayoutKit",
            ]),
        .target(
            name: "AutoLayoutKit",
            dependencies: [
                .product(name: "CoreSwift", package: "CoreSwift"),
            ]),
        .target(
            name: "FlexLayoutCore",
            dependencies: [
                .product(name: "CoreCxx", package: "CoreSwift"),
            ]),
        .target(
            name: "FlexLayoutKit",
            dependencies: [
                "FlexLayoutCore",
                .product(name: "CoreSwift", package: "CoreSwift"),
            ],
            exclude: ["FlexLayout+Gen.swift.gyb"]
        ),
        .testTarget(
            name: "LayoutKitTests",
            dependencies: ["LayoutKit"]),
    ]
)
