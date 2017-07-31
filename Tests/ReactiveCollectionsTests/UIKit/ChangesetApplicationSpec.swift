import Quick
import Nimble
import ReactiveSwift
import ReactiveCocoa
import ReactiveCollections
import UIKit

class ChangesetApplicationSpec: QuickSpec {
	override func spec() {
		describe("applying to UITableView") {
			var tableView: MockUITableView!

			beforeEach {
				tableView = MockUITableView()
				expect(tableView.updateCount) == 0
				expect(tableView.isUpdating) == false
			}

			it("should acknowledge insertions") {
				tableView.reactive.apply(Changeset(inserts: [10, 12, 15]),
				                         toSection: 0)
				expect(tableView.insertions) == [[0, 10], [0, 12], [0, 15]]
				expect(tableView.updateCount) == 1
				expect(tableView.isUpdating) == false

				tableView.reactive.apply(Changeset(inserts: [20, 22, 25]),
				                         toSection: 1)
				expect(tableView.insertions) == [[1, 20], [1, 22], [1, 25]]
				expect(tableView.updateCount) == 2
				expect(tableView.isUpdating) == false
			}

			it("should acknowledge deletions") {
				tableView.reactive.apply(Changeset(removals: [10, 12, 15]),
				                         toSection: 0)
				expect(tableView.deletions) == [[0, 10], [0, 12], [0, 15]]
				expect(tableView.updateCount) == 1
				expect(tableView.isUpdating) == false

				tableView.reactive.apply(Changeset(removals: [20, 22, 25]),
				                         toSection: 1)
				expect(tableView.deletions) == [[1, 20], [1, 22], [1, 25]]
				expect(tableView.updateCount) == 2
				expect(tableView.isUpdating) == false
			}


			it("should acknowledge reloads") {
				tableView.reactive.apply(Changeset(mutations: [10, 12, 15]),
				                         toSection: 0)
				expect(tableView.reloads) == [[0, 10], [0, 12], [0, 15]]
				expect(tableView.updateCount) == 1
				expect(tableView.isUpdating) == false

				tableView.reactive.apply(Changeset(mutations: [20, 22, 25]),
				                         toSection: 1)
				expect(tableView.reloads) == [[1, 20], [1, 22], [1, 25]]
				expect(tableView.updateCount) == 2
				expect(tableView.isUpdating) == false
			}
		}

		describe("applying to UICollectionView") {
			var collectionView: MockUICollectionView!

			beforeEach {
				collectionView = MockUICollectionView()
				expect(collectionView.updateCount) == 0
				expect(collectionView.isUpdating) == false
			}

			it("should acknowledge insertions") {
				collectionView.reactive.apply(Changeset(inserts: [10, 12, 15]),
				                              toSection: 0)
				expect(collectionView.insertions) == [[0, 10], [0, 12], [0, 15]]
				expect(collectionView.updateCount) == 1
				expect(collectionView.isUpdating) == false

				collectionView.reactive.apply(Changeset(inserts: [20, 22, 25]),
				                              toSection: 1)
				expect(collectionView.insertions) == [[1, 20], [1, 22], [1, 25]]
				expect(collectionView.updateCount) == 2
				expect(collectionView.isUpdating) == false
			}

			it("should acknowledge deletions") {
				collectionView.reactive.apply(Changeset(removals: [10, 12, 15]),
				                              toSection: 0)
				expect(collectionView.deletions) == [[0, 10], [0, 12], [0, 15]]
				expect(collectionView.updateCount) == 1
				expect(collectionView.isUpdating) == false

				collectionView.reactive.apply(Changeset(removals: [20, 22, 25]),
				                              toSection: 1)
				expect(collectionView.deletions) == [[1, 20], [1, 22], [1, 25]]
				expect(collectionView.updateCount) == 2
				expect(collectionView.isUpdating) == false
			}


			it("should acknowledge reloads") {
				collectionView.reactive.apply(Changeset(mutations: [10, 12, 15]),
				                              toSection: 0)
				expect(collectionView.reloads) == [[0, 10], [0, 12], [0, 15]]
				expect(collectionView.updateCount) == 1
				expect(collectionView.isUpdating) == false

				collectionView.reactive.apply(Changeset(mutations: [20, 22, 25]),
				                              toSection: 1)
				expect(collectionView.reloads) == [[1, 20], [1, 22], [1, 25]]
				expect(collectionView.updateCount) == 2
				expect(collectionView.isUpdating) == false
			}
		}
	}
}

private class MockUITableView: UITableView {
	var updateCount = 0
	var isUpdating = false
	var insertions: [IndexPath] = []
	var deletions: [IndexPath] = []
	var moves: [(IndexPath, IndexPath)] = []
	var reloads: [IndexPath] = []

	init() {
		super.init(frame: .zero, style: .plain)
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	override func beginUpdates() {
		isUpdating = true
		updateCount += 1

		insertions = []
		deletions = []
		moves = []
		reloads = []
	}

	override func endUpdates() {
		isUpdating = false
	}

	override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
		insertions += indexPaths
	}

	override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
		deletions += indexPaths
	}

	override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
		moves.append((indexPath, newIndexPath))
	}

	override func reloadRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
		reloads += indexPaths
	}
}

private class MockUICollectionView: UICollectionView {
	var updateCount = 0
	var isUpdating = false
	var insertions: [IndexPath] = []
	var deletions: [IndexPath] = []
	var moves: [(IndexPath, IndexPath)] = []
	var reloads: [IndexPath] = []

	init() {
		super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
		isUpdating = true
		updateCount += 1

		insertions = []
		deletions = []
		moves = []
		reloads = []

		updates?()

		isUpdating = false

		completion?(true)
	}

	override func insertItems(at indexPaths: [IndexPath]) {
		insertions += indexPaths
	}

	override func deleteItems(at indexPaths: [IndexPath]) {
		deletions += indexPaths
	}

	override func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
		moves.append((indexPath, newIndexPath))
	}
	
	override func reloadItems(at indexPaths: [IndexPath]) {
		reloads += indexPaths
	}
}
