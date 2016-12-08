import XCTest
import ReactiveSwift
import Result
@testable import ReactiveCollections

class ReactiveArrayTests: XCTestCase {

    // MARK: - Initializers

    func test_initializer() {

        let emptyArray = ReactiveArray([1, 2, 3])

        XCTAssertEqual(emptyArray[emptyArray.indices], [1, 2, 3])
    }

    func test_empty_initializer() {

        let emptyArray = ReactiveArray<Int>()

        XCTAssertEqual(emptyArray[emptyArray.indices], [])
    }

    func test_literal_initializer() {

        let array: ReactiveArray = [1, 2, 3]

        XCTAssertEqual(array[array.indices], [1, 2, 3])
    }

    func test_repeating_initializer() {

        let array = ReactiveArray(repeating: 0, count: 5)

        XCTAssertEqual(array[array.indices], ArraySlice(repeating: 0, count: 5))
    }

    // MARK: - Lifecycle

    func test_lifecycle() {

        let exp = expectation(description: "")

        var array = ReactiveArray([1, 2, 3]) as Optional

        _ = array?.signal.observeCompleted {
            exp.fulfill()
        }

        array = nil

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Properties tests

    func test_count() {
        XCTAssertEqual(ReactiveArray([Int]()).count, 0)
        XCTAssertEqual(ReactiveArray([1, 2, 3]).count, 3)
    }

    func test_first() {
        XCTAssertNil(ReactiveArray([Int]()).first)
        XCTAssertEqual(ReactiveArray([1, 2, 3]).first, 1)
    }

    func test_is_empty() {
        XCTAssertEqual(ReactiveArray([Int]()).isEmpty, true)
        XCTAssertEqual(ReactiveArray([1, 2, 3]).isEmpty, false)
    }

    func test_end_index() {
        XCTAssertEqual(ReactiveArray([Int]()).endIndex, 0)
        XCTAssertEqual(ReactiveArray([1, 2, 3]).endIndex, 3)
    }

    func test_start_index() {
        XCTAssertEqual(ReactiveArray([Int]()).startIndex, 0)
        XCTAssertEqual(ReactiveArray([1, 2, 3]).startIndex, 0)
    }

    // MARK: - Subscripting tests

    func test_subscripting_access() {

        let array = ReactiveArray([1, 2, 3])

        XCTAssertEqual(array[0], 1)
        XCTAssertEqual(array[1], 2)
        XCTAssertEqual(array[2], 3)
    }

    func test_subscripting_insert_at_tail() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array[3] = 4

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
        XCTAssertEqual(patches, [
            .insert(element: 4, at: 3)
            ])
    }

    func test_subscripting_insert_at_head() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array[0] = 3

        XCTAssertEqual(array[array.indices], [3, 1, 2, 3])
        XCTAssertEqual(patches, [
            .insert(element: 3, at: 0)
            ])
    }

    // MARK: - Replace tests

    func test_replace_range() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.replaceSubrange(1...2, with: [1, 1])

        XCTAssertEqual(array[array.indices], [1, 1, 1])
        XCTAssertEqual(patches, [
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2),
            .insert(element: 1, at: 1),
            .insert(element: 1, at: 2)
            ])

        patches.removeAll()

        array.replaceSubrange(0...1, with: [0, 0, 0])

        XCTAssertEqual(array[array.indices], [0, 0, 0, 1])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 1, at: 1),
            .insert(element: 0, at: 0),
            .insert(element: 0, at: 1),
            .insert(element: 0, at: 2)
            ])

        patches.removeAll()

        array.replaceSubrange(0...0, with: [1])

        XCTAssertEqual(array[array.indices], [1, 0, 0, 1])
        XCTAssertEqual(patches, [
            .remove(element: 0, at: 0),
            .insert(element: 1, at: 0)
            ])

        patches.removeAll()

        array.replaceSubrange(array.indices, with: Array(0...5))

        XCTAssertEqual(array[array.indices], [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 0, at: 1),
            .remove(element: 0, at: 2),
            .remove(element: 1, at: 3),
            .insert(element: 0, at: 0),
            .insert(element: 1, at: 1),
            .insert(element: 2, at: 2),
            .insert(element: 3, at: 3),
            .insert(element: 4, at: 4),
            .insert(element: 5, at: 5)
            ])
    }

    // MARK: - Append tests

    func test_append() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.append(4)

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
        XCTAssertEqual(patches, [
            .insert(element: 4, at: 3)
            ])
    }

    func test_append_contents_of() {

        var patches: [[Change<Int>]] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches.append($0) }

        array.append(contentsOf: [4, 5, 6])

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(patches, [
            [
                .insert(element: 4, at: 3)
            ],
            [
                .insert(element: 5, at: 4)
            ],
            [
                .insert(element: 6, at: 5)
            ]
            ])
    }

    // MARK: - Insert tests

    func test_insert_at_index() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.insert(4, at: array.endIndex)

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
        XCTAssertEqual(patches, [
                .insert(element: 4, at: 3)
            ])

        patches.removeAll()

        array.insert(0, at: 0)

        XCTAssertEqual(array[array.indices], [0, 1, 2, 3, 4])
        XCTAssertEqual(patches, [
            .insert(element: 0, at: 0)
            ])
    }

    func test_insert_contents_of() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.insert(contentsOf: [4, 5, 6], at: 0)

        XCTAssertEqual(array[array.indices], [4, 5, 6, 1, 2, 3])
        XCTAssertEqual(patches, [
            .insert(element: 4, at: 0),
            .insert(element: 5, at: 1),
            .insert(element: 6, at: 2)
            ])
    }

    // MARK: - Remove tests

    func test_remove_all() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeAll()

        XCTAssertEqual(array[array.indices], [])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2)
            ])
    }

    func test_remove_all_and_keep_capacity() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        let initialCapacity = array.capacity

        array.signal.observeValues { patches += $0 }

        array.removeAll(keepingCapacity: true)

        XCTAssertEqual(array[array.indices], [])
        XCTAssertEqual(array.capacity, initialCapacity)
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2)
            ])
    }

    func test_remove_first() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeFirst()

        XCTAssertEqual(array[array.indices], [2, 3])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0)
            ])
    }

    func test_remove_first2() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeFirst(2)

        XCTAssertEqual(array[array.indices], [3])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 2, at: 1)
            ])
    }

    func test_remove_first_all() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeFirst(3)

        XCTAssertEqual(array[array.indices], [])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2)
            ])
    }

    func test_remove_last() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeLast()

        XCTAssertEqual(array[array.indices], [1, 2])
        XCTAssertEqual(patches, [
            .remove(element: 3, at: 2)
            ])
    }

    func test_remove_last2() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeLast(2)

        XCTAssertEqual(array[array.indices], [1])
        XCTAssertEqual(patches, [
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2)
            ])
    }

    func test_remove_last_all() {

        var patches: [Change<Int>] = []

        var array = ReactiveArray([1, 2, 3])

        array.signal.observeValues { patches += $0 }

        array.removeLast(3)

        XCTAssertEqual(array[array.indices], [])
        XCTAssertEqual(patches, [
            .remove(element: 1, at: 0),
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2)
            ])
    }

    func test_remove_at_index() {

        var patches: [Change<Int>] = []
        
        var array = ReactiveArray([1, 2, 3])
        
        array.signal.observeValues { patches += $0 }
        
        array.remove(at: 1)
        
        XCTAssertEqual(array[array.indices], [1, 3])
        XCTAssertEqual(patches, [
            .remove(element: 2, at: 1)
            ])
    }

    func test_remove_range() {
        
        var patches: [Change<Int>] = []
        
        var array = ReactiveArray([1, 2, 3])
        
        array.signal.observeValues { patches += $0 }

        array.removeSubrange(1...2)
        
        XCTAssertEqual(array[array.indices], [1])
        XCTAssertEqual(patches, [
            .remove(element: 2, at: 1),
            .remove(element: 3, at: 2)
            ])
    }
}

// MARK: - Helpers

// TODO: Keep while we haven't `SE-0143: Conditional conformances` (expected in Swift 4)
extension Change where T: Equatable {

    func equal(to other: Change<T>) -> Bool {
        switch (self, other) {
        case let (.insert(leftElement, leftIndex), .insert(rightElement, rightIndex)):
            return leftElement == rightElement && leftIndex == rightIndex
        case let (.remove(leftElement, leftIndex), .remove(rightElement, rightIndex)):
            return leftElement == rightElement && leftIndex == rightIndex
        default:
            return false
        }
    }
}

private func equal<T: Equatable>(_ lhs: [Change<T>], _ rhs: [Change<T>]) -> Bool {
    if lhs.count != rhs.count {
        return false
    }

    for (index, element) in lhs.enumerated() {
        if element.equal(to: rhs[index]) == false {
            return false
        }
    }

    return true
}

func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> [Change<T>],
    _ expression2: @autoclosure () -> [Change<T>],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line)
{
    let (lhs, rhs) = (expression1(), expression2())
    XCTAssertTrue(equal(lhs, rhs), "(\"\(lhs)\") is not equal to (\"\(rhs)\")")
}

func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> [[Change<T>]],
    _ expression2: @autoclosure () -> [[Change<T>]],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line)
{
    let (lhs, rhs) = (expression1(), expression2())

    if lhs.count != rhs.count {
        XCTAssertFalse(false, "(\"\(lhs)\") is not equal to (\"\(rhs)\")")
    }

    for (index, leftChanges) in lhs.enumerated() {
        XCTAssertTrue(equal(leftChanges, rhs[index]), "(\"\(lhs)\") is not equal to (\"\(rhs)\")")
    }
}
