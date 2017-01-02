import PackageDescription

let package = Package(
    name: "ReactiveCollections",
    dependencies: [
        .Package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", majorVersion: 1),
    ]
)
