// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShelfKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ShelfKit", targets: ["ShelfKit"]),
    ],
    targets: [
        .target(name: "ShelfKit"),
        .testTarget(name: "ShelfKitTests", dependencies: ["ShelfKit"]),
    ]
)
