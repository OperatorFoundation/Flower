// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
name: "Flower",
    platforms: [
       .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Flower",
            targets: ["Flower"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "3.0.5"),
        .package(url: "https://github.com/OperatorFoundation/Transport", from: "2.3.5"),
        .package(url: "https://github.com/apple/swift-log", from: "1.4.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Flower",
            dependencies: ["Datable", "Transport", .product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "FlowerTests",
            dependencies: ["Flower"]),
    ],
    swiftLanguageVersions: [.v5]
)
