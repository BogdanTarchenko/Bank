// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BankShared",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BankShared", targets: ["BankShared"])
    ],
    targets: [
        .target(name: "BankShared")
    ]
)
