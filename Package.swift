// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
name: "Flower",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Flower",
            targets: ["Flower"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "3.1.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.4.2"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue", from: "0.1.1"),
        .package(url: "https://github.com/OperatorFoundation/Transmission", from: "1.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Flower",
            dependencies: ["Datable", "SwiftQueue", "Transmission", .product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "FlowerTests",
            dependencies: ["Flower"]),
    ],
    swiftLanguageVersions: [.v5]
)
