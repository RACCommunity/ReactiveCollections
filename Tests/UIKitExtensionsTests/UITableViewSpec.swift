import UIKit
import ReactiveSwift
import ReactiveCollections
import Quick
import Nimble

class UITableViewSpec: QuickSpec {
	override func spec() {
		describe("UITableView") {
			var window: UIWindow!
			var tableView: UITableView!
			var items: ReactiveArray<String>!

			beforeEach {
				window = UIWindow()

				tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 800),
				                        style: .plain)
				tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ItemCell")
				window.addSubview(tableView)

				items = ReactiveArray()
			}

			func setup(with itemCount: Int = 0) {
				items.modify { $0.append(contentsOf: (0 ..< itemCount).lazy.map { "\($0)" }) }
				expect(items.count) == itemCount

				tableView.reactive.collection <~ items.producer.map { item, cellFactory in
					let cell = cellFactory("ItemCell")
					cell.textLabel?.text = item
					return cell
				}
			}

			it("should have one section only") {
				setup()
				expect(tableView.numberOfSections) == 1
			}

			it("should have acknowledged existing rows") {
				setup(with: 16)
				expect(tableView.numberOfRows(inSection: 0)) == 16
			}

			it("should remove all rows as the array is emptied") {
				setup(with: 16)
				expect(tableView.numberOfRows(inSection: 0)) == 16

				items.modify { $0.removeAll() }
				expect(tableView.numberOfRows(inSection: 0)) == 0
			}

			it("should insert rows when the array has new items") {
				setup()

				for i in 0 ..< 10 {
					items.modify { $0.append("\(i)") }
					expect(tableView.numberOfRows(inSection: 0)) == i + 1
					expect(tableView.cellForRow(at: IndexPath(row: i, section: 0))?.textLabel?.text) == "\(i)"
				}
			}

			it("should support backward traversal") {
				setup(with: 16)
				expect(tableView.numberOfRows(inSection: 0)) == 16

				for i in (0 ..< 16).reversed() {
					expect(tableView.cellForRow(at: IndexPath(row: i, section: 0))?.textLabel?.text) == "\(i)"
				}
			}

			it("should support random traversal") {
				setup(with: 128)
				expect(tableView.numberOfRows(inSection: 0)) == 128

				let indices = Array(shuffling: 0 ..< 128)

				for i in indices {
					let indexPath = IndexPath(row: i, section: 0)
					tableView.scrollToRow(at: indexPath, at: .top, animated: false)
					expect(tableView.cellForRow(at: indexPath)?.textLabel?.text) == "\(i)"
				}
			}

			it("should remove a previously inserted item") {
				setup()

				items.modify { $0.append(contentsOf: ["1", "2"]) }
				expect(tableView.numberOfRows(inSection: 0)) == 2
				expect(tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.textLabel?.text) == "1"
				expect(tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.textLabel?.text) == "2"

				_ = items.modify { $0.remove(at: 1) }
				expect(tableView.numberOfRows(inSection: 0)) == 1
				expect(tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.textLabel?.text) == "1"
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
