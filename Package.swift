// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SPMFileCacheBug",
    products: [
        .library(
            name: "SPMFileCacheBug",
            targets: ["SPMFileCacheBug"]),
    ],
    targets: [
        .target(
            name: "SPMFileCacheBug",
            plugins: [.plugin(name: "VerifyFileList")]),
        .plugin(name: "VerifyFileList", capability: .buildTool())
    ]
)
