// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "union-gestures",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionGestures",
            targets: ["UnionGestures"]
        ),
    ],
    targets: [
        .target(
            name: "UnionGestures"
        ),
    ]
)
