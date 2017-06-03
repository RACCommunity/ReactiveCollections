import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

extension Reactive where Base: UITableView {
	public var collection: BindingTarget<(UITableView) -> Void> {
		return BindingTarget(lifetime: lifetime) { [weak base] in
			if let base = base {
				$0(base)
			}
		}
	}
}

// FIXME: Swift 4 Associated Type Constraints
//
// extension SignalProducer
// where Value: IndexingDelta, Error == NoError {
extension SignalProducer
where Value: IndexingDelta,
      Value.IndexPairs.Iterator.Element == (Value.Snapshot.Index, Value.Snapshot.Index),
      Value.Snapshot.Index == Value.ChangeRepresentation.Iterator.Element,
      Value.Snapshot.IndexDistance.Stride: SignedInteger,
      Error == NoError {
	public func map(
		_ transform: @escaping (Value.Snapshot.Iterator.Element, (String) -> UITableViewCell) -> UITableViewCell
	) -> SignalProducer<(UITableView) -> Void, NoError> {
		return map(transform, bidirectional: false)
	}

	fileprivate func map(
		_ transform: @escaping (Value.Snapshot.Iterator.Element, (String) -> UITableViewCell) -> UITableViewCell,
		bidirectional: Bool
	) -> SignalProducer<(UITableView) -> Void, NoError> {
		return SignalProducer<(UITableView) -> Void, NoError> { observer, disposable in
			observer.send(value: { tableView in
				let array: ReactiveArray<DefaultSection<Value>> = [DefaultSection(deltas: self)]
				let dataSource = TableViewDataSource(deltas: array.producer,
				                                     tableView: tableView,
				                                     transform: transform,
				                                     canTraverseBidirectionally: bidirectional)

				tableView.dataSource = dataSource
				disposable += dataSource.start()
				disposable += { _ = array }
			})
		}
	}
}

// FIXME: Swift 4 Associated Type Constraints
//
// extension SignalProducer
// where Value: IndexingDelta, Value.Snapshot: BidirectionalCollection, Error == NoError {
extension SignalProducer
where Value: IndexingDelta,
      Value.Snapshot: BidirectionalCollection,
      Value.IndexPairs.Iterator.Element == (Value.Snapshot.Index, Value.Snapshot.Index),
      Value.Snapshot.Index == Value.ChangeRepresentation.Iterator.Element,
      Value.Snapshot.IndexDistance.Stride: SignedInteger,
      Error == NoError {
	public func map(
		_ transform: @escaping (Value.Snapshot.Iterator.Element, (String) -> UITableViewCell) -> UITableViewCell
	) -> SignalProducer<(UITableView) -> Void, NoError> {
		return map(transform, bidirectional: true)
	}
}

// FIXME: Swift 4 Associated Type Constraints
//
// private final class ReactiveUITableViewDataSource<Delta>: NSObject, UITableViewDataSource
// where Delta: IndexingDelta, Delta.Snapshot.Element: IndexingDeltaSection
private final class TableViewDataSource<Delta: IndexingDelta>: DataSource<Delta>, UITableViewDataSource
where Delta.IndexPairs.Iterator.Element == (Delta.Snapshot.Index,Delta.Snapshot.Index),
      Delta.Snapshot.Index == Delta.ChangeRepresentation.Iterator.Element,
      Delta.Snapshot.IndexDistance.Stride: SignedInteger,
      Delta.Snapshot.Iterator.Element: IndexingDeltaSection,
      Delta.Snapshot.Iterator.Element.Delta: IndexingDelta,
      Delta.Snapshot.Iterator.Element.Delta.IndexPairs.Iterator.Element == (Delta.Snapshot.Iterator.Element.Delta.Snapshot.Index, Delta.Snapshot.Iterator.Element.Delta.Snapshot.Index),
      Delta.Snapshot.Iterator.Element.Delta.Snapshot.Index == Delta.Snapshot.Iterator.Element.Delta.ChangeRepresentation.Iterator.Element,
      Delta.Snapshot.Iterator.Element.Delta.Snapshot.IndexDistance.Stride: SignedInteger {
	typealias Transform = (Delta.Snapshot.Iterator.Element.Delta.Snapshot.Iterator.Element, (String) -> UITableViewCell) -> UITableViewCell

	private let transform: Transform
	private weak var tableView: UITableView?

	init(deltas: SignalProducer<Delta, NoError>, tableView: UITableView, transform: @escaping Transform, canTraverseBidirectionally: Bool) {
		self.transform = transform
		self.tableView = tableView
		super.init(deltas: deltas, canInnerTraverseBidirectionally: canTraverseBidirectionally)
	}

	override func update(_ action: ((Event) -> Void) -> Void) {
		guard let t = tableView else { return }

		action { event in
			switch event {
			case .reloadAll:
				t.reloadData()

			case let .insertSections(indices):
				t.insertSections(indices, with: .automatic)

			case let .deleteSections(indices):
				t.deleteSections(indices, with: .automatic)

			case let .reloadSections(indices):
				t.reloadSections(indices, with: .automatic)

			case let .moveSection(source, destination):
				t.moveSection(source, toSection: destination)

			case let .insertRows(indices, section):
				t.insertRows(at: indices.map { IndexPath(row: $0, section: section) }, with: .automatic)

			case let .deleteRows(indices, section):
				t.deleteRows(at: indices.map { IndexPath(row: $0, section: section) }, with: .automatic)

			case let .reloadRows(indices, section):
				t.reloadRows(at: indices.map { IndexPath(row: $0, section: section) }, with: .automatic)

			case let .moveRow(source, destination, section):
				t.moveRow(at: IndexPath(row: source, section: section), to: IndexPath(row: destination, section: section))
			}
		}
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return sectionCount
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return transform(self[indexPath.section, indexPath.row]) { reuseIdentifier in
			return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rowCount(section: section)
	}
}
