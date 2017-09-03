import UIKit
import ReactiveSwift

public struct UITableViewAnimationSpec {
	public static let `default` = UITableViewAnimationSpec()

	public let reloads: UITableViewRowAnimation
	public let deletes: UITableViewRowAnimation
	public let inserts: UITableViewRowAnimation

	public init(
		reloads: UITableViewRowAnimation = .fade,
		deletes: UITableViewRowAnimation = .automatic,
		inserts: UITableViewRowAnimation = .automatic
	) {
		(self.deletes, self.reloads, self.inserts) = (deletes, reloads, inserts)
	}
}

extension Reactive where Base: UITableView {
	public func apply(_ changeset: Changeset, toSection section: Int, with spec: UITableViewAnimationSpec = .default) {
		base.beginUpdates()
		defer { base.endUpdates() }

		base.deleteRows(at: changeset.removals.map { IndexPath(row: $0, section: section) }, with: spec.deletes)
		base.reloadRows(at: changeset.mutations.map { IndexPath(row: $0, section: section) }, with: spec.reloads)
		base.insertRows(at: changeset.inserts.map { IndexPath(row: $0, section: section) }, with: spec.inserts)

		for move in changeset.moves {
			base.moveRow(at: IndexPath(row: move.source, section: section),
			             to: IndexPath(row: move.destination, section: section))

			if move.isMutated {
				base.reloadRows(at: [IndexPath(row: move.source, section: section)], with: spec.reloads)
			}
		}
	}
}
