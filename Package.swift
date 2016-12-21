import PackageDescription

let package = Package(
    name: "ReactiveCollections",
    dependencies: [
        .Package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", versions: Version(1, 0, 0, prereleaseIdentifiers: ["rc", "2"])..<Version(1, .max, .max)),
    ]
)
