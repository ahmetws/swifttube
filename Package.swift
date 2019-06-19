// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "swifttube",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from:"3.0.0-rc.2.2"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/nodes-vapor/paginator.git", from: "3.0.0-rc")
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "Leaf", "MongoKitten", "Paginator"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

