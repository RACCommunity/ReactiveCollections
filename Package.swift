import Foundation
import PackageDescription

var isSwiftPackagerManagerTest: Bool {
    return ProcessInfo.processInfo.environment["SWIFTPM_TEST_ReactiveCollections"] == "YES"
}

let package = Package(
    name: "ReactiveCollections",
    dependencies: {
        var deps: [Package.Dependency] = [
	    .Package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", majorVersion: 2),
	]
        if isSwiftPackagerManagerTest {
            deps += [
                .Package(url: "https://github.com/Quick/Quick.git", majorVersion: 1, minor: 1),
                .Package(url: "https://github.com/Quick/Nimble.git", majorVersion: 7, minor: 0),
            ]
        }
	return deps
    }(),
    exclude: ["Sources/UIKit/", "Sources/AppKit/", "Tests/ReactiveCollectionTests/UIKit/", "Tests/ReactiveCollectionsTests/AppKit/"]
)
