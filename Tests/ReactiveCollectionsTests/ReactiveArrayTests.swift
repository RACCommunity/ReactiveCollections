import Foundation
import XCTest
import ReactiveSwift
import Result
import Nimble
@testable import ReactiveCollections

class ReactiveArrayTests: XCTestCase {

	typealias Change<T> = ReactiveArray<T>.Change

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


		_ = array?.signal.observeCompleted { completedExpectation.fulfill() }

		_ = array?.signal.on(disposed: { disposedExpectation.fulfill() })

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

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array[0] = 3

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [3, 2, 3],
				inserts: .empty,
				deletes: .empty,
				updates: IndexSet(integer: 0)
			)
		)

		XCTAssertEqual(array[array.indices], [3, 2, 3])
		expect(changes) == expectedChanges
	}

	// MARK: - Replace tests

	func test_replace_range() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.replaceSubrange(1...2, with: [1, 1])

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1, 1, 1],
				inserts: .empty,
				deletes: .empty,
				updates: IndexSet(1...2)
			)
		)

		XCTAssertEqual(array[array.indices], [1, 1, 1])
		expect(changes) == expectedChanges

		array.replaceSubrange(0...1, with: [0, 0, 0])

		expectedChanges.append(
			Delta(
				previous: [1, 1, 1],
				current: [0, 0, 0, 1],
				inserts: IndexSet(integer: 2),
				deletes: .empty,
				updates: IndexSet(0...1)
			)
		)

		XCTAssertEqual(array[array.indices], [0, 0, 0, 1])
		expect(changes) == expectedChanges

		array.replaceSubrange(0...0, with: [1])

		expectedChanges.append(
			Delta(
				previous: [0, 0, 0, 1],
				current: [1, 0, 0, 1],
				inserts: .empty,
				deletes: .empty,
				updates: IndexSet(integer: 0)
			)
		)

		XCTAssertEqual(array[array.indices], [1, 0, 0, 1])
		expect(changes) == expectedChanges

		array.replaceSubrange(array.indices, with: Array(0...5))

		expectedChanges.append(
			Delta(
				previous: [1, 0, 0, 1],
				current: [0, 1, 2, 3, 4, 5],
				inserts: IndexSet(4...5),
				deletes: .empty,
				updates: IndexSet(0...3)
			)
		)

		XCTAssertEqual(array[array.indices], [0, 1, 2, 3, 4, 5])
		expect(changes) == expectedChanges
	}

	// MARK: - Append tests

	func test_append() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.append(4)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1, 2, 3, 4],
				inserts: IndexSet(integer: 3),
				deletes: .empty,
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
		expect(changes) == expectedChanges
	}

	func test_append_contents_of() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.append(contentsOf: [4, 5, 6])

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1, 2, 3, 4, 5, 6],
				inserts: IndexSet(3..<6),
				deletes: .empty,
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1, 2, 3, 4, 5, 6])
		expect(changes) == expectedChanges
	}

	// MARK: - Insert tests

	func test_insert_at_index() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.insert(4, at: array.endIndex)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1, 2, 3, 4],
				inserts: IndexSet(integer: 3),
				deletes: .empty,
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1, 2, 3, 4])
		expect(changes) == expectedChanges

		array.insert(0, at: 0)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3, 4],
				current: [0, 1, 2, 3, 4],
				inserts: IndexSet(integer: 0),
				deletes: .empty,
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [0, 1, 2, 3, 4])
		expect(changes) == expectedChanges
	}

	func test_insert_contents_of() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.insert(contentsOf: [4, 5, 6], at: 0)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [4, 5, 6, 1, 2, 3],
				inserts: IndexSet(0..<3),
				deletes: .empty,
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [4, 5, 6, 1, 2, 3])
		expect(changes) == expectedChanges
	}

	// MARK: - Remove tests

	func test_remove_all() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeAll()

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [],
				inserts: .empty,
				deletes: IndexSet(0..<3),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [])
		expect(changes) == expectedChanges
	}

	func test_remove_all_and_keep_capacity() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeAll(keepingCapacity: true)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [],
				inserts: .empty,
				deletes: IndexSet(0..<3),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [])
		expect(changes) == expectedChanges
	}

	func test_remove_first() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		XCTAssertEqual(array.removeFirst(), 1)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [2, 3],
				inserts: .empty,
				deletes: IndexSet(integer: 0),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [2, 3])
		expect(changes) == expectedChanges
	}

	func test_remove_first2() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeFirst(2)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [3],
				inserts: .empty,
				deletes: IndexSet(0...1),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [3])
		expect(changes) == expectedChanges
	}

	func test_remove_first_all() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeFirst(3)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [],
				inserts: .empty,
				deletes: IndexSet(0...2),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [])
		expect(changes) == expectedChanges
	}

	func test_remove_last() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		XCTAssertEqual(array.removeLast(), 3)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1, 2],
				inserts: .empty,
				deletes: IndexSet(integer: 2),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1, 2])
		expect(changes) == expectedChanges
	}

	func test_remove_last2() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeLast(2)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1],
				inserts: .empty,
				deletes: IndexSet(1..<3),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1])
		expect(changes) == expectedChanges
	}

	func test_remove_last_all() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeLast(3)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [],
				inserts: .empty,
				deletes: IndexSet(0..<3),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [])
		expect(changes) == expectedChanges
	}

	func test_remove_at_index() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		XCTAssertEqual(array.remove(at: 1), 2)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1, 3],
				inserts: .empty,
				deletes: IndexSet(integer: 1),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1, 3])
		expect(changes) == expectedChanges
	}

	func test_remove_subrange() {

		var changes: [Change<Int>] = []
		var expectedChanges: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.signal.observeValues { changes.append($0) }

		array.removeSubrange(1...2)

		expectedChanges.append(
			Delta(
				previous: [1, 2, 3],
				current: [1],
				inserts: .empty,
				deletes: IndexSet(1..<3),
				updates: .empty
			)
		)

		XCTAssertEqual(array[array.indices], [1])
		expect(changes) == expectedChanges
	}

	// MARK: - Producer tests

	func test_producer() {

		var changes: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		array.producer.startWithValues { changes.append($0) }

		array.append(4)

		array.removeAll()

		let expectedChanges: [Change<Int>] = [
			Delta(
				previous: [],
				current: [1, 2, 3],
				inserts: IndexSet(0..<3),
				deletes: .empty,
				updates: .empty
			),
			Delta(
				previous: [1, 2, 3],
				current: [1, 2, 3, 4],
				inserts: IndexSet(integer: 3),
				deletes: .empty,
				updates: .empty
			),
			Delta(
				previous: [1, 2, 3, 4],
				current: [],
				inserts: .empty,
				deletes: IndexSet(0...3),
				updates: .empty
			)
		]

		zip(changes, expectedChanges).forEach { XCTAssertEqual($0, $1) }
	}

	func test_producer_with_up_to_date_changes() {

		var changes: [Change<Int>] = []

		let array = ReactiveArray([1, 2, 3])

		let producer = array.producer

		array.append(4)

		producer.startWithValues { changes.append($0) }

		array.removeAll()

		let expectedChanges: [Change<Int>] = [
			Delta(
				previous: [],
				current: [1, 2, 3, 4],
				inserts: IndexSet(0..<4),
				deletes: .empty,
				updates: .empty
			),
			Delta(
				previous: [1, 2, 3, 4],
				current: [],
				inserts: .empty,
				deletes: IndexSet(0..<4),
				updates: .empty
			)
		]

		zip(changes, expectedChanges).forEach { XCTAssertEqual($0, $1) }
	}

	func test_producer_should_not_retain_the_array() {
		var array = ReactiveArray([1, 2, 3]) as Optional
		weak var weakArray = array

		withExtendedLifetime(array!.producer) {
			array = nil
			XCTAssertNil(weakArray)
		}
	}

	func test_producer_should_send_last_snapshot_even_if_array_has_deinitialized() {
		var array = ReactiveArray([1, 2, 3]) as Optional
		let producer = array!.producer
		array = nil

		var latestSnapshot: ContiguousArray<Int>?
		var completed = false
		var hasUnanticipatedEvents = false

		producer.start { event in
			switch event {
			case let .value(delta):
				latestSnapshot = delta.current

			case .completed:
				completed = true

			case .interrupted, .failed:
				hasUnanticipatedEvents = true
			}
		}

		XCTAssertEqual(latestSnapshot ?? [], [1, 2, 3])
		XCTAssertTrue(completed)
		XCTAssertFalse(hasUnanticipatedEvents)
	}
}

// MARK: - Linux support

#if os(Linux)
extension ReactiveArrayTests {

	static var allTests: [(String, (ReactiveArrayTests) -> () throws -> Void)] {
		return [
			("test_initializer", test_initializer),
			("test_empty_initializer", test_empty_initializer),
			("test_literal_initializer", test_literal_initializer),
			("test_repeating_initializer", test_repeating_initializer),
			("test_lifecycle", test_lifecycle),
			("test_count", test_count),
			("test_first", test_first),
			("test_is_empty", test_is_empty),
			("test_end_index", test_end_index),
			("test_start_index", test_start_index),
			("test_subscripting_access", test_subscripting_access),
			("test_subscripting_replace_at_head", test_subscripting_replace_at_head),
			("test_replace_range", test_replace_range),
			("test_append", test_append),
			("test_append_contents_of", test_append_contents_of),
			("test_insert_at_index", test_insert_at_index),
			("test_insert_contents_of", test_insert_contents_of),
			("test_remove_all", test_remove_all),
			("test_remove_all_and_keep_capacity", test_remove_all_and_keep_capacity),
			("test_remove_first", test_remove_first),
			("test_remove_first2", test_remove_first2),
			("test_remove_first_all", test_remove_first_all),
			("test_remove_last", test_remove_last),
			("test_remove_last2", test_remove_last2),
			("test_remove_last_all", test_remove_last_all),
			("test_remove_at_index", test_remove_at_index),
			("test_remove_subrange", test_remove_subrange),
			("test_producer", test_producer),
			("test_producer_with_up_to_date_changes", test_producer_with_up_to_date_changes),
			("test_producer_should_not_retain_the_array", test_producer_should_not_retain_the_array),
			("test_producer_should_send_last_snapshot_even_if_array_has_deinitialized", test_producer_should_send_last_snapshot_even_if_array_has_deinitialized)
		]
	}
}
#endif

// MARK: - Helpers

func XCTAssertEqual<T>(
	_ expression1: @autoclosure () -> [ReactiveArray<T>.Change],
	_ expression2: @autoclosure () -> [ReactiveArray<T>.Change],
	_ message: @autoclosure () -> String = "",
	file: StaticString = #file,
	line: UInt = #line)
	where T : Equatable
{
	let (lhs, rhs) = (expression1(), expression2())
	let equal = zip(lhs, rhs)
		.map(==)
		.reduce(true, { $0 && $1 })
	XCTAssertTrue(equal, "(\"\(lhs)\") is not equal to (\"\(rhs)\")", file: file, line: line)
}

func XCTAssertEqual<T>(
	_ expression1: @autoclosure () -> ReactiveArray<T>.Change,
	_ expression2: @autoclosure () -> ReactiveArray<T>.Change,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #file,
	line: UInt = #line)
	where T : Equatable
{
	let (lhs, rhs) = (expression1(), expression2())
	XCTAssert(lhs == rhs, "(\"\(lhs)\") is not equal to (\"\(rhs)\")", file: file, line: line)
}
