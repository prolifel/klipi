// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Klipi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Klipi",
            targets: ["Klipi"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Klipi",
            path: "."
        )
    ]
)