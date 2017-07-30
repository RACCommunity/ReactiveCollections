import Foundation
import ReactiveSwift
import Result
import Nimble
import Quick
@testable import ReactiveCollections

private typealias TestSnapshot = ReactiveArray<Int>.Snapshot

class ReactiveArraySpec: QuickSpec {
	override func spec() {
		describe("init") {
			it("initializer") {
				let emptyArray = ReactiveArray([1, 2, 3])
				expect(emptyArray) == [1, 2, 3]
			}

			it("empty_initializer") {
				let emptyArray = ReactiveArray<Int>()
				expect(emptyArray) == []
			}

			it("literal_initializer") {
				let array: ReactiveArray = [1, 2, 3]
				expect(array) == [1, 2, 3]
			}
		}

		it("lifecycle") {
			var array: ReactiveArray<Int>? = ReactiveArray([1, 2, 3])

			var isCompleted = false
			var isDisposed = false

			array!.signal
				.on(disposed: { isDisposed = true })
				.observeCompleted { isCompleted = true }

			expect(isCompleted) == false
			expect(isDisposed) == false

			array = nil

			expect(isCompleted) == true
			expect(isDisposed) == true
		}

		// MARK: - Properties tests

		describe("collection properties") {
			it("count") {
				expect(ReactiveArray([Int]()).count) == 0
				expect(ReactiveArray([1, 2, 3]).count) == 3
			}

			it("isEmpty") {
				expect(ReactiveArray([Int]()).isEmpty) == true
				expect(ReactiveArray([1, 2, 3]).isEmpty) == false
			}

			it("endIndex") {
				expect(ReactiveArray([Int]()).endIndex) == 0
				expect(ReactiveArray([1, 2, 3]).endIndex) == 3
			}

			it("startIndex") {
				expect(ReactiveArray([Int]()).startIndex) == 0
				expect(ReactiveArray([1, 2, 3]).startIndex) == 0
			}
		}

		describe("subscript") {
			it("get") {
				let array = ReactiveArray([1, 2, 3])

				expect(array[0]) == 1
				expect(array[1]) == 2
				expect(array[2]) == 3
			}

			it("get and set") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0[0] = 3 }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [3, 2, 3],
						changeset: Changeset(inserts: [],
						                     removals: [],
						                     mutations: IndexSet(integer: 0))
					)
				)

				expect(array) == [3, 2, 3]
				expect(changes.last!) == expectedChanges.last!
			}
		}

		describe("MutableView") {
			it("replace_range") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.replaceSubrange(1...2, with: [1, 1]) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 1, 1],
						changeset: Changeset(inserts: [],
						                     removals: [],
						                     mutations: IndexSet(integersIn: 1...2))
					)
				)

				expect(array) == [1, 1, 1]
				expect(changes.last!) == expectedChanges.last!

				array.modify { $0.replaceSubrange(0...1, with: [0, 0, 0]) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 1, 1],
						current: [0, 0, 0, 1],
						changeset: Changeset(inserts: IndexSet(integer: 2),
						                     removals: [],
						                     mutations: IndexSet(integersIn: 0...1))
					)
				)

				expect(array) == [0, 0, 0, 1]
				expect(changes.last!) == expectedChanges.last!

				array.modify { $0.replaceSubrange(0...0, with: [1]) }

				expectedChanges.append(
					TestSnapshot(
						previous: [0, 0, 0, 1],
						current: [1, 0, 0, 1],
						changeset: Changeset(inserts: [],
						                     removals: [],
						                     mutations: IndexSet(integer: 0))
					)
				)

				expect(array) == [1, 0, 0, 1]
				expect(changes.last!) == expectedChanges.last!

				array.modify { $0.replaceSubrange(array.indices, with: Array(0...5)) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 0, 0, 1],
						current: [0, 1, 2, 3, 4, 5],
						changeset: Changeset(inserts: IndexSet(integersIn: 4...5),
						                     removals: [],
						                     mutations: IndexSet(integersIn: 0...3))
					)
				)

				expect(array) == [0, 1, 2, 3, 4, 5]
				expect(changes.last!) == expectedChanges.last!
			}

			it("append") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.append(4) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 2, 3, 4],
						changeset: Changeset(inserts: IndexSet(integer: 3),
						                     removals: [],
						                     mutations: [])
					)
				)

				expect(array) == [1, 2, 3, 4]
				expect(changes.last!) == expectedChanges.last!
			}

			it("append_contents_of") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.append(contentsOf: [4, 5, 6]) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 2, 3, 4, 5, 6],
						changeset: Changeset(inserts: IndexSet(integersIn: 3..<6),
						                     removals: [],
						                     mutations: [])
					)
				)

				expect(array) == [1, 2, 3, 4, 5, 6]
				expect(changes.last!) == expectedChanges.last!
			}

			it("insert_at_index") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.insert(4, at: array.endIndex) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 2, 3, 4],
						changeset: Changeset(inserts: IndexSet(integer: 3),
						                     removals: [],
						                     mutations: [])
					)
				)

				expect(array) == [1, 2, 3, 4]
				expect(changes.last!) == expectedChanges.last!

				array.modify { $0.insert(0, at: 0) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3, 4],
						current: [0, 1, 2, 3, 4],
						changeset: Changeset(inserts: IndexSet(integer: 0),
						                     removals: [],
						                     mutations: [])
					)
				)

				expect(array) == [0, 1, 2, 3, 4]
				expect(changes.last!) == expectedChanges.last!
			}

			it("insert_contents_of") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.insert(contentsOf: [4, 5, 6], at: 0) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [4, 5, 6, 1, 2, 3],
						changeset: Changeset(inserts: IndexSet(integersIn: 0..<3),
						                     removals: [],
						                     mutations: [])
					)
				)

				expect(array) == [4, 5, 6, 1, 2, 3]
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_all") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeAll() }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0..<3),
						                     mutations: [])
					)
				)

				expect(array) == []
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_all_and_keep_capacity") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeAll(keepingCapacity: true) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0..<3),
						                     mutations: [])
					)
				)

				expect(array) == []
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_first") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				expect(array.modify { $0.removeFirst() }) == 1

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [2, 3],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integer: 0),
						                     mutations: [])
					)
				)

				expect(array) == [2, 3]
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_first2") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeFirst(2) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [3],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0...1),
						                     mutations: [])
					)
				)

				expect(array) == [3]
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_first_all") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeFirst(3) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0...2),
						                     mutations: [])
					)
				)

				expect(array) == []
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_last") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				expect(array.modify { $0.removeLast() }) == 3

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 2],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integer: 2),
						                     mutations: [])
					)
				)

				expect(array) == [1, 2]
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_last2") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeLast(2) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 1..<3),
						                     mutations: [])
					)
				)

				expect(array) == [1]
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_last_all") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeLast(3) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0..<3),
						                     mutations: [])
					)
				)

				expect(array) == []
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_at_index") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				expect(array.modify { $0.remove(at: 1) }) == 2

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 3],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integer: 1),
						                     mutations: [])
					)
				)

				expect(array) == [1, 3]
				expect(changes.last!) == expectedChanges.last!
			}

			it("remove_subrange") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				var expectedChanges: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.signal.observeValues { changes.append($0) }

				array.modify { $0.removeSubrange(1...2) }

				expectedChanges.append(
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 1..<3),
						                     mutations: [])
					)
				)

				expect(array) == [1]
				expect(changes.last!) == expectedChanges.last!
			}

			describe("operation sequences") {
				var latestDelta: ReactiveArray<Int>.Snapshot!
				var array: ReactiveArray<Int>!

				beforeEach {
					array = [1, 2, 3]
					array.signal.observeValues { latestDelta = $0 }
				}

				it("should treat replacement of the mutable view as `removeAll`") {
					array.modify { view in
						view = []
					}

					expect(array) == []
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: [],
					                                    changeset: Changeset(inserts: [],
					                                                         removals: IndexSet(integersIn: 0 ..< 3),
					                                                         mutations: []))
				}

				it("should treat replacement of the mutable view as `removeAll`, and append the given array") {
					array.modify { view in
						view = []
						view.append(contentsOf: [8, 9, 0])
					}

					expect(array) == [8, 9, 0]
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: [8, 9, 0],
					                                    changeset: Changeset(inserts: IndexSet(integersIn: 0 ..< 3),
					                                                         removals: IndexSet(integersIn: 0 ..< 3),
					                                                         mutations: []))
				}

				it("should insert at removed indices") {
					array.modify { view in
						view.removeFirst(3)
						view.insert(contentsOf: [8, 9, 0], at: 0)
					}

					expect(array) == [8, 9, 0]
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: [8, 9, 0],
					                                    changeset: Changeset(inserts: IndexSet(0 ..< 3),
					                                                         removals: IndexSet(0 ..< 3),
					                                                         mutations: []))
				}

				it("should remove uncommitted inserts") {
					array.modify { view in
						view.insert(contentsOf: [8, 9, 0], at: 0)
						view.removeFirst(3)
					}

					expect(array) == [1, 2, 3]
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: [1, 2, 3],
					                                    changeset: Changeset(inserts: [],
					                                                         removals: [],
					                                                         mutations: []))
				}

				it("should accomodate uncommitted inserts before the elements to be removed") {
					array.modify { view in
						view.insert(100, at: 1)
						view.remove(at: 3)
					}

					expect(array) == [1, 100, 2]
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: [1, 100, 2],
					                                    changeset: Changeset(inserts: IndexSet(integer: 1),
					                                                         removals: IndexSet(integer: 2),
					                                                         mutations: []))
				}

				it("should accomodate uncommitted inserts before the elements to be updated") {
					array.modify { view in
						view.insert(100, at: 1)
						view[3] = 200
					}

					expect(array) == [1, 100, 2, 200]
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: [1, 100, 2, 200],
					                                    changeset: Changeset(inserts: IndexSet(integer: 1),
					                                                         removals: [],
					                                                         mutations: IndexSet(integer: 2)))
				}

				it("should replace the content, sort the array and remove the last elements") {
					let values: ContiguousArray = [5, 7, 6, 100, 21, 5, 0, 3, 102, 8, 35, 16, 30, 101]
					let sorted = ContiguousArray(values.sorted().dropLast(3))

					array.modify { view in
						view.replaceSubrange(view.startIndex ..< view.endIndex, with: values)
						view.sort(by: <)
						view.removeLast(3)
					}

					expect(array) == sorted
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: sorted,
					                                    changeset: Changeset(inserts: IndexSet(integersIn: 3 ..< 11),
					                                                         removals: [],
					                                                         mutations: IndexSet(integersIn: 0 ..< 3)))
				}

				it("should insert the content, remove the original elements, sort the array and remove the last elements") {
					let values: ContiguousArray = [5, 7, 6, 100, 21, 5, 0, 3, 102, 8, 35, 16, 30, 101]
					let sorted = ContiguousArray(values.sorted().dropLast(3))

					array.modify { view in
						view.insert(contentsOf: values, at: 0)
						view.removeLast(3)
						view.sort(by: <)
						view.removeLast(3)
					}

					expect(array) == sorted
					expect(latestDelta) == TestSnapshot(previous: [1, 2, 3],
					                                    current: sorted,
					                                    changeset: Changeset(inserts: IndexSet(integersIn: 0 ..< 11),
					                                                         removals: IndexSet(integersIn: 0 ..< 3),
					                                                         mutations: []))
				}
			}
		}

		describe("producer") {
			it("producer") {
				var changes: [ReactiveArray<Int>.Snapshot] = []

				let array = ReactiveArray([1, 2, 3])

				array.producer.startWithValues { changes.append($0) }

				array.modify { $0.append(4) }

				array.modify { $0.removeAll() }

				let expectedChanges: [ReactiveArray<Int>.Snapshot] = [
					TestSnapshot(
						previous: nil,
						current: [1, 2, 3],
						changeset: Changeset(inserts: IndexSet(integersIn: 0..<3),
						                     removals: [],
						                     mutations: [])
					),
					TestSnapshot(
						previous: [1, 2, 3],
						current: [1, 2, 3, 4],
						changeset: Changeset(inserts: IndexSet(integer: 3),
						                     removals: [],
						                     mutations: [])
					),
					TestSnapshot(
						previous: [1, 2, 3, 4],
						current: [],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0...3),
						                     mutations: [])
					)
				]
				
				zip(changes, expectedChanges).forEach { expect($0) == $1 }
			}
			
			it("producer_with_up_to_date_changes") {
				var changes: [ReactiveArray<Int>.Snapshot] = []
				
				let array = ReactiveArray([1, 2, 3])
				
				let producer = array.producer
				
				array.modify { $0.append(4) }
				
				producer.startWithValues { changes.append($0) }
				
				array.modify { $0.removeAll() }
				
				let expectedChanges: [ReactiveArray<Int>.Snapshot] = [
					TestSnapshot(
						previous: nil,
						current: [1, 2, 3, 4],
						changeset: Changeset(inserts: IndexSet(integersIn: 0..<4),
						                     removals: [],
						                     mutations: [])
					),
					TestSnapshot(
						previous: [1, 2, 3, 4],
						current: [],
						changeset: Changeset(inserts: [],
						                     removals: IndexSet(integersIn: 0..<4),
						                     mutations: [])
					)
				]
				
				zip(changes, expectedChanges).forEach { expect($0) == $1 }
			}
			
			it("producer_should_not_retain_the_array") {
				var array = ReactiveArray([1, 2, 3]) as Optional
				weak var weakArray = array
				
				withExtendedLifetime(array!.producer) {
					array = nil
					expect(weakArray).to(beNil())
				}
			}
			
			it("producer_should_send_last_snapshot_even_if_array_has_deinitialized") {
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
				
				expect(Array(latestSnapshot ?? [])) == [1, 2, 3]
				expect(completed) == true
				expect(hasUnanticipatedEvents) == false
			}
		}
	}
}

extension IndexSet {
	internal init(integersIn ranges: CountableRange<Int>...) {
		self.init()
		for range in ranges {
			insert(integersIn: range)
		}
	}
}
