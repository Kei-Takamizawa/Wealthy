// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WealthyCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "WealthyCore", targets: ["WealthyCore"])],
    targets: [
        .target(name: "WealthyCore"),
        .testTarget(name: "WealthyCoreTests", dependencies: ["WealthyCore"])
    ],
    swiftLanguageModes: [.v6]
)
