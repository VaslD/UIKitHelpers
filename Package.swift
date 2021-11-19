// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "UIKit Helpers",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "UIKitHelpers", targets: ["UIKitHelpers"])
    ],
    dependencies: [],
    targets: [
        .target(name: "UIKitHelpers"),
    ]
)
