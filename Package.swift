// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
name: "Flower",
    platforms: [
       .macOS(.v13),
       .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Flower",
            targets: ["Flower"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.1.0"),
        .package(url: "https://github.com/OperatorFoundation/Datable", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols", branch: "main"),
        .package(url: "https://github.com/apple/swift-log", from: "1.4.2"),
        .package(url: "https://github.com/OperatorFoundation/SwiftHexTools", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Transmission", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Flower",
            dependencies: ["Datable", "SwiftQueue", "Transmission", "SwiftHexTools", .product(name: "Crypto", package: "swift-crypto"), .product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "FlowerTests",
            dependencies: ["Flower", "InternetProtocols", "Transmission"]),
    ],
    swiftLanguageVersions: [.v5]
)
