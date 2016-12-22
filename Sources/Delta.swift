import Foundation

public extension IndexSet {

	public static var empty: IndexSet {
		return IndexSet()
	}
}

public struct Delta<Snapshot: Collection, ChangeRepresentation> {
	public let previous: Snapshot
	public let current: Snapshot

	public let inserts: ChangeRepresentation
	public let deletes: ChangeRepresentation
	public let updates: ChangeRepresentation
}

extension Delta where Snapshot.Iterator.Element: Equatable, ChangeRepresentation: Equatable {

	public static func ==(lhs: Delta<Snapshot, ChangeRepresentation>, rhs: Delta<Snapshot, ChangeRepresentation>) -> Bool {

		guard lhs.inserts == rhs.inserts
			&& lhs.deletes == rhs.deletes
			else { return false }

		return lhs.previous == rhs.previous && lhs.current == rhs.current
	}
}

fileprivate extension Collection where Iterator.Element: Equatable {

	fileprivate static func ==(lhs: Self, rhs: Self) -> Bool {
		guard lhs.count == rhs.count else {
			return false
		}

		for (left, rigtht) in zip(lhs, rhs) {
			if left != right {
				return false
			}
		}

		return true
	}
}
