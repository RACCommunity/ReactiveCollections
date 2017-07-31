import UIKit
import ReactiveSwift

extension Reactive where Base: UICollectionView {
	public func apply(_ changeset: Changeset, toSection section: Int) {
		func update() {
			base.deleteItems(at: changeset.removals.map { IndexPath(item: $0, section: section) })
			base.reloadItems(at: changeset.mutations.map { IndexPath(item: $0, section: section) })
			base.insertItems(at: changeset.inserts.map { IndexPath(item: $0, section: section) })

			for move in changeset.moves {
				base.moveItem(at: IndexPath(item: move.source, section: section),
				              to: IndexPath(item: move.destination, section: section))

				if move.isMutated {
					base.reloadItems(at: [IndexPath(item: move.source, section: section)])
				}
			}
		}

		base.performBatchUpdates(update, completion: nil)
	}
}
