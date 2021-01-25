// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CacheKit",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "CacheKit",
            targets: ["CacheKit"]),
    ],
    dependencies: [
        .package(
            name: "FMDB",
            url: "https://github.com/ccgus/fmdb.git",
            .exact("2.7.7"))
    ],
    targets: [
        .target(
            name: "CacheKit",
            dependencies: ["FMDB"]),
        .testTarget(
            name: "CacheKitTests",
            dependencies: ["CacheKit"]),
    ]
)
