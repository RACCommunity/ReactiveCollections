import Foundation
import PackageDescription

var isSwiftPackagerManagerTest: Bool {
    return ProcessInfo.processInfo.environment["SWIFTPM_TEST_ReactiveCollections"] == "YES"
}

let package = Package(
    name: "ReactiveCollections",
    dependencies: {
        var deps: [Package.Dependency] = [
	    .Package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", majorVersion: 1),
	]
        if isSwiftPackagerManagerTest {
            deps += [
                .Package(url: "https://github.com/Quick/Quick.git", majorVersion: 1, minor: 1),
                .Package(url: "https://github.com/Quick/Nimble.git", majorVersion: 6, minor: 1),
            ]
        }
	return deps
    }()
)
