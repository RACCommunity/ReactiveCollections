import Foundation
import ReactiveSwift
import ReactiveCollections
import Quick
import Nimble
import Result

private final class TestDataSource: DataSource<ReactiveArray<ReactiveArray<String>>.Delta> {
	var latestEvents: [TestDataSource.Event] = []

	override func update(_ action: ((TestDataSource.Event) -> Void) -> Void) {
		latestEvents = []
		action { self.latestEvents.append($0) }
	}
}

class DataSourceSpec: QuickSpec {
	override func spec() {
		describe("DataSource") {
			var dataSource: TestDataSource!
			var items: ReactiveArray<ReactiveArray<String>>!

			beforeEach {
				items = ReactiveArray()
				dataSource = TestDataSource(deltas: items.producer)
			}

			func setup(with itemCounts: [Int] = []) {
				items.modify { items in
					for count in itemCounts {
						let strings = (0 ..< count).map(String.init)
						items.append(ReactiveArray(strings))

						let last = items.last.map { Array($0) }
						expect(last) == strings
						expect(last?.count) == count
					}
				}

				expect(items.count) == itemCounts.count

				_ = dataSource.start()
				expect(dataSource.latestEvents) == (!itemCounts.isEmpty ? [.insertSections(IndexSet(integersIn: 0 ..< itemCounts.count))] : [])
			}

			it("should have no section initially") {
				setup()

				expect(dataSource.sectionCount) == 0
			}

			it("should have multiple sections initially") {
				setup(with: [0, 1, 2, 3])

				expect(dataSource.sectionCount) == 4
				expect(dataSource.rowCount(section: 0)) == 0
				expect(dataSource.rowCount(section: 1)) == 1
				expect(dataSource.rowCount(section: 2)) == 2
				expect(dataSource.rowCount(section: 3)) == 3
			}

			it("should replace a section") {
				setup(with: [0, 2, 0])
				expect(dataSource.sectionCount) == 3
				expect(dataSource.rowCount(section: 1)) == 2

				let strings = (10 ..< 15).map(String.init)
				items.modify { $0[1] = ReactiveArray(strings) }

				expect(dataSource.sectionCount) == 3
				expect(dataSource.rowCount(section: 1)) == 5
				expect((0 ..< 5).map { dataSource[1, $0] }) == strings
			}

			it("should remove a section") {
				setup(with: [0, 2, 0])
				expect(dataSource.sectionCount) == 3

				_ = items.modify { $0.remove(at: 1) }
				expect(dataSource.sectionCount) == 2
				expect(dataSource.latestEvents) == [.deleteSections([1])]

				_ = items.modify { $0.remove(at: 0) }
				expect(dataSource.sectionCount) == 1
				expect(dataSource.latestEvents) == [.deleteSections([0])]

				_ = items.modify { $0.remove(at: 0) }
				expect(dataSource.sectionCount) == 0
				expect(dataSource.latestEvents) == [.deleteSections([0])]
			}

			it("should remove all sections as the outer collection is emptied") {
				setup(with: [3, 4])
				expect(dataSource.rowCount(section: 0)) == 3
				expect(dataSource.rowCount(section: 1)) == 4

				items.modify { $0.removeAll() }
				expect(dataSource.sectionCount) == 0
				expect(dataSource.latestEvents) == [.deleteSections([0, 1])]
			}

			it("should insert rows when the array has new items") {
				setup(with: [0])

				let subitems = items[0]
				for i in 0 ..< 10 {
					subitems.modify { $0.append("\(i)") }
					expect(dataSource.rowCount(section: 0)) == i + 1
					expect(dataSource[0, i]) == "\(i)"
				}
			}

			it("should support backward traversal") {
				setup(with: [16])
				expect(dataSource.rowCount(section: 0)) == 16

				for i in (0 ..< 16).reversed() {
					expect(dataSource[0, i]) == "\(i)"
				}
			}

			it("should support random traversal") {
				setup(with: [128])
				expect(dataSource.rowCount(section: 0)) == 128

				let indices = Array(shuffling: 0 ..< 128)

				for i in indices {
					expect(dataSource[0, i]) == "\(i)"
				}
			}

			it("should remove a previously inserted item") {
				setup(with: [0])

				let subitems = items[0]
				subitems.modify { $0.append(contentsOf: ["1", "2"]) }
				expect(dataSource.rowCount(section: 0)) == 2
				expect(dataSource[0, 0]) == "1"
				expect(dataSource[0, 1]) == "2"

				_ = subitems.modify { $0.remove(at: 1) }
				expect(dataSource.rowCount(section: 0)) == 1
				expect(dataSource[0, 0]) == "1"
			}

			// TODO: Add move operation tests.
			//
			// `ReactiveArray` does not support move operations yet.
		}
	}
}

extension Array {
	fileprivate init<C: Collection>(shuffling elements: C) where C.Iterator.Element == Element {
		self.init(elements)

		for i in startIndex ..< endIndex {
			let target = Int(arc4random() >> 1) % endIndex
			
			if target != i {
				swap(&self[i], &self[target])
			}
		}
	}
}
