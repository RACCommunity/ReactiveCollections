import XCTest
import Quick

@testable import ReactiveCollectionsTests

Quick.QCKMain([ReactiveArraySpec.self, CollectionDiffingSpec.self])
