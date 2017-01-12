import Foundation

// FIXME: (Swift 4.0) Arbitrary requirements
// Ideally, we would have this constraint:
// Indices.Iterator.Element == Snapshot.Index
public struct Delta<Snapshot: Collection, Indices: Collection> {
	public let previous: Snapshot
	public let current: Snapshot

	public let inserts: Indices
	public let deletes: Indices
	public let updates: Indices
}

extension Delta where Snapshot.Iterator.Element: Equatable, Indices: Equatable {
	public static func ==(lhs: Delta<Snapshot, Indices>, rhs: Delta<Snapshot, Indices>) -> Bool {
		guard lhs.inserts == rhs.inserts && lhs.deletes == rhs.deletes else {
			return false
		}

		return lhs.previous == rhs.previous && lhs.current == rhs.current
	}
}

fileprivate extension Collection where Iterator.Element: Equatable {
	fileprivate static func ==(lhs: Self, rhs: Self) -> Bool {
		guard lhs.count == rhs.count else {
			return false
		}

		return zip(lhs, rhs).first(where: !=) == nil
	}
}
