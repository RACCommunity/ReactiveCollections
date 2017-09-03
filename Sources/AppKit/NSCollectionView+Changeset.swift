import AppKit
import ReactiveSwift

extension Reactive where Base: NSCollectionView {
	@available(macOS 10.11, *)
	public func apply(_ changeset: Changeset, toSection section: Int) {
		func update() {
			base.deleteItems(at: Set(changeset.removals.map { IndexPath(item: $0, section: section) }))
			base.reloadItems(at: Set(changeset.mutations.map { IndexPath(item: $0, section: section) }))
			base.insertItems(at: Set(changeset.inserts.map { IndexPath(item: $0, section: section) }))

			for move in changeset.moves {
				base.moveItem(at: IndexPath(item: move.source, section: section),
				              to: IndexPath(item: move.destination, section: section))

				if move.isMutated {
					base.reloadItems(at: [IndexPath(item: move.source, section: section)])
				}
			}
		}

		base.performBatchUpdates(update, completionHandler: nil)
	}
}
