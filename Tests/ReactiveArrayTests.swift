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

        let completedExpectation = expectation(description: "Completed expectation")
        let disposedExpectation = expectation(description: "Disposed expectation")

        var array = ReactiveArray([1, 2, 3]) as Optional


        _ = array?.signal.observeCompleted(completedExpectation.fulfill)
        
        _ = array?.signal.on(disposed: disposedExpectation.fulfill)

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

    func test_subscripting_replace_at_head() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array[3] = 4

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
        XCTAssertNotNil(changeset)
        XCTAssertTrue(changeset! == Changeset(
            inserts: [.item(4, at: 3)],
            removes: [],
            updates: []
            )
        )
    }

    func test_subscripting_insert_at_head() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array[0] = 3

        XCTAssertEqual(array[array.indices], [3, 1, 2, 3])
        XCTAssertNotNil(changeset)
        XCTAssertTrue(changeset! == Changeset(
            inserts: [.item(3, at: 0)],
            removes: [],
            updates: []
            )
        )
    }

    // MARK: - Replace tests

    func test_replace_range() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.replaceSubrange(1...2, with: [1, 1])

        XCTAssertEqual(array[array.indices], [1, 1, 1])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [.items([1, 1], range: 1..<3)],
            removes: [.items([2, 3], range: 1..<3)],
            updates: []
            )
        )

        changeset = nil

        array.replaceSubrange(0...1, with: [0, 0, 0])

        XCTAssertEqual(array[array.indices], [0, 0, 0, 1])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [.items([0, 0, 0], range: 0..<3)],
            removes: [.items([1, 1], range: 0..<2)],
            updates: []
            )
        )

        changeset = nil

        array.replaceSubrange(0...0, with: [1])

        XCTAssertEqual(array[array.indices], [1, 0, 0, 1])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [.item(1, at: 0)],
            removes: [.item(0, at: 0)],
            updates: []
            )
        )

        changeset = nil

        array.replaceSubrange(array.indices, with: Array(0...5))

        XCTAssertEqual(array[array.indices], [0, 1, 2, 3, 4, 5])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [.items([0, 1, 2, 3, 4, 5], range: 0..<6)],
            removes: [.items([1, 0, 0, 1], range: 0..<4)],
            updates: []
            )
        )
    }

    // MARK: - Append tests

    func test_append() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.append(4)

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
        XCTAssertNotNil(changeset)
        XCTAssertTrue(changeset! == Changeset(
            inserts: [.item(4, at: 3)],
            removes: [],
            updates: []
            )
        )
    }

    func test_append_contents_of() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.append(contentsOf: [4, 5, 6])

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4, 5, 6])
        XCTAssertNotNil(changeset)
        XCTAssertTrue(changeset! == Changeset(
            inserts: [.items([4, 5, 6], range: 3..<6)],
            removes: [],
            updates: []
            )
        )
    }

    // MARK: - Insert tests

    func test_insert_at_index() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.insert(4, at: array.endIndex)

        XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [.item(4, at: 3)],
            removes: [],
            updates: []
            )
        )

        changeset = nil

        array.insert(0, at: 0)

        XCTAssertEqual(array[array.indices], [0, 1, 2, 3, 4])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [.item(0, at: 0)],
            removes: [],
            updates: []
            )
        )
    }

    func test_insert_contents_of() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.insert(contentsOf: [4, 5, 6], at: 0)

        XCTAssertEqual(array[array.indices], [4, 5, 6, 1, 2, 3])
        XCTAssertNotNil(changeset)
        XCTAssertTrue(changeset! == Changeset(
            inserts: [.items([4, 5, 6], range: 0..<3)],
            removes: [],
            updates: []
            )
        )
    }

    // MARK: - Remove tests

    func test_remove_all() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeAll()

        XCTAssertEqual(array[array.indices], [])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([1, 2, 3], range: 0..<3)],
            updates: []
            )
        )
    }

    func test_remove_all_and_keep_capacity() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeAll(keepingCapacity: true)

        XCTAssertEqual(array[array.indices], [])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([1, 2, 3], range: 0..<3)],
            updates: []
            )
        )
    }

    func test_remove_first() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        XCTAssertEqual(array.removeFirst(), 1)

        XCTAssertEqual(array[array.indices], [2, 3])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.item(1, at: 0)],
            updates: []
            )
        )
    }

    func test_remove_first2() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeFirst(2)

        XCTAssertEqual(array[array.indices], [3])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([1, 2], range: 0..<2)],
            updates: []
            )
        )
    }

    func test_remove_first_all() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeFirst(3)

        XCTAssertEqual(array[array.indices], [])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([1, 2, 3], range: 0..<3)],
            updates: []
            )
        )
    }

    func test_remove_last() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        XCTAssertEqual(array.removeLast(), 3)

        XCTAssertEqual(array[array.indices], [1, 2])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.item(3, at: 2)],
            updates: []
            )
        )
    }

    func test_remove_last2() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeLast(2)

        XCTAssertEqual(array[array.indices], [1])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([2, 3], range: 1..<3)],
            updates: []
            )
        )
    }

    func test_remove_last_all() {

        var changeset: Changeset<Int>? = nil

        let array = ReactiveArray([1, 2, 3])

        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeLast(3)

        XCTAssertEqual(array[array.indices], [])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([1, 2, 3], range: 0..<3)],
            updates: []
            )
        )
    }

    func test_remove_at_index() {

        var changeset: Changeset<Int>? = nil
        
        let array = ReactiveArray([1, 2, 3])
        
        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }
        
        XCTAssertEqual(array.remove(at: 1), 2)
        
        XCTAssertEqual(array[array.indices], [1, 3])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.item(2, at: 1)],
            updates: []
            )
        )
    }

    func test_remove_subrange() {
        
        var changeset: Changeset<Int>? = nil
        
        let array = ReactiveArray([1, 2, 3])
        
        array.signal.observeValues {
            XCTAssertNil(changeset)
            changeset = $0
        }

        array.removeSubrange(1...2)
        
        XCTAssertEqual(array[array.indices], [1])
        XCTAssertNotNil(changeset)
        XCTAssertEqual(changeset!, Changeset(
            inserts: [],
            removes: [.items([2, 3], range: 1..<3)],
            updates: []
            )
        )
    }

    // MARK: - Producer tests

    func test_producer() {

        var changesets: [Changeset<Int>] = []

        let array = ReactiveArray([1, 2, 3])

        array.producer.startWithValues { changesets.append($0) }

        array.append(4)

        array.removeAll()

        let expectedChangesets = [
            Changeset(
                inserts: [.items([1, 2, 3], range: 0..<3)],
                removes: [],
                updates: []
            ),
            Changeset(
                inserts: [.item(4, at: 3)],
                removes: [],
                updates: []
            ),
            Changeset(
                inserts: [],
                removes: [.items([1, 2, 3, 4], range: 0..<4)],
                updates: []
            )
        ]

        zip(changesets, expectedChangesets).forEach { XCTAssertEqual($0, $1) }
    }

    func test_producer_with_up_to_date_changes() {

        var changesets: [Changeset<Int>] = []

        let array = ReactiveArray([1, 2, 3])

        let producer = array.producer

        array.append(4)

        producer.startWithValues { changesets.append($0) }

        array.removeAll()

        let expectedChangesets = [
            Changeset(
                inserts: [.items([1, 2, 3, 4], range: 0..<4)],
                removes: [],
                updates: []
            ),
            Changeset(
                inserts: [],
                removes: [.items([1, 2, 3, 4], range: 0..<4)],
                updates: []
            )
        ]

        zip(changesets, expectedChangesets).forEach { XCTAssertEqual($0, $1) }
    }

    func test_producer_not_retaining_array() {

        let completedExpectation = expectation(description: "Completed expectation")

        var array = ReactiveArray([1, 2, 3]) as Optional

        let producer = array!.producer

        array = nil

        producer
            .on(completed: {
                completedExpectation.fulfill()
            }, value: { _ in
                XCTAssertFalse(false, "Producer should not send any values") }
            )
            .start()

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

// MARK: - Helpers

func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> Changeset<T>,
    _ expression2: @autoclosure () -> Changeset<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line)
{
    let (lhs, rhs) = (expression1(), expression2())
    XCTAssert(lhs == rhs, "(\"\(lhs)\") is not equal to (\"\(rhs)\")", file: file, line: line)
}
