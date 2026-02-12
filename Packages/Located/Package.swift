// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Located",
    platforms: [
        .iOS("18.4"),
        .watchOS("11.4"),
    ],
    products: [
        .library(
            name: "Located",
            targets: ["Located"]
        ),
    ],
    targets: [
        .target(
            name: "Located"
        ),
        .testTarget(
            name: "LocatedTests",
            dependencies: ["Located"]
        ),
    ]
)
