import Foundation

/// Represents an atomic batch of changes made to a collection.
///
/// A `Changeset` represents changes as **offsets** of elements. You may
/// subscript a collection of zero-based indexing with the offsets, e.g. `Array`. You must
/// otherwise convert the offsets into indices before subscripting.
///
/// # Implicit order between offsets.
///
/// Removal offsets precede insertion offsets. Move offset pairs are semantically
/// equivalent to a pair of removal offset (source) and an insertion offset (destination).
///
/// ## Example: Reproducing an array.
///
/// Given a previous version of a collection, a current version of a collection, and a
/// `Changeset`, we can reproduce the current version by applying the `Changeset` to
/// the previous version.
///
/// - note: `Array` is a zero-based container, thus being able to consume zero-based
/// offsets directly. If you are working upon non-zero-based or undetermined collection
/// types, you **must** first convert offsets into indices.
///
/// 1. Clone the previous version.
///
///    ```
///    var elements = previous
///    ```
///
/// 2. Copy mutated elements specified by `mutations`.
///
///    `mutations` offsets are invariant. So it can simply be conducted as:
///    ```
///    for range in changeset.mutations.rangeView {
///        elements[range] = current[range]
///    }
///    ```
///
/// 3. Perform removals specified by `removals` and `moves` (sources).
///
///    ```
///    let removals = changeset.removals
///        .union(IndexSet(changeset.moves.map { $0.source }))
///
///    for range in removals.rangeView.reversed() {
///        elements.removeSubrange(range)
///    }
///    ```
///
/// 4. Perform inserts specified by `inserts` and `moves` (destinations).
///
///    ```
///    let inserts = changeset.inserts
///        .union(IndexSet(changeset.moves.map { $0.destination }))
///
///    for range in inserts.rangeView {
///        elements.insert(contentsOf: current[range], at: range.lowerBound)
///    }
///    ```
///
public struct Changeset {
	/// Represents the context of a move operation applied to a collection.
	public struct Move {
		public let source: Int
		public let destination: Int
		public let isMutated: Bool

		public init(source: Int, destination: Int, isMutated: Bool) {
			(self.source, self.destination, self.isMutated) = (source, destination, isMutated)
		}
	}

	/// The offsets of inserted elements in the current version of the collection.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the current version, the
	///              start index and the offset.
	public var inserts = IndexSet()

	/// The offsets of removed elements in the previous version of the collection.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the previous version, the
	///              start index and the offset.
	public var removals = IndexSet()

	/// The offsets of position-invariant mutations that are valid across both versions
	/// of the collection.
	///
	/// `mutations` only implies an invariant relative position. The actual indexes can
	/// be different, depending on the collection type.
	///
	/// If an element has both changed and moved, it is instead included in `moves` with
	/// an asserted mutation flag.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the relevant versions, the
	///              start index and the offset.
	public var mutations = IndexSet()

	/// The offset pairs of moves with a mutation flag as the associated value.
	///
	/// The source offset is semantically equivalent to a removal offset, while the
	/// destination offset is semantically equivalent to an insertion offset.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the relevant versions, the
	///              start index and the offset.
	public var moves = [Move]()

	public init() {}

	public init(inserts: IndexSet = [], removals: IndexSet = [], mutations: IndexSet = [], moves: [Move] = []) {
		(self.inserts, self.removals) = (inserts, removals)
		(self.mutations, self.moves) = (mutations, moves)
	}

	public init<C: Collection>(initial: C) {
		inserts = IndexSet(integersIn: 0 ..< Int(initial.count))
	}
}

#if !swift(>=3.2)
	extension SignedInteger {
		fileprivate init<I: SignedInteger>(_ integer: I) {
			self.init(integer.toIntMax())
		}
	}
#endif

extension Changeset.Move: Equatable {
	public static func == (left: Changeset.Move, right: Changeset.Move) -> Bool {
		return left.isMutated == right.isMutated && left.source == right.source && left.destination == right.destination
	}
}

extension Changeset: Equatable {
	public static func == (left: Changeset, right: Changeset) -> Bool {
		return left.inserts == right.inserts && left.removals == right.removals && left.mutations == right.mutations && left.moves == right.moves
	}
}

// Better debugging experience
extension Changeset: CustomDebugStringConvertible {
	public var debugDescription: String {
		func moveDescription(_ move: Move) -> String {
			return "\(move.source) -> \(move.isMutated ? "*" : "")\(move.destination)"
		}

		return ([
			"- inserted \(inserts.count) item(s) at [\(inserts.map(String.init).joined(separator: ", "))]" as String,
			"- deleted \(removals.count) item(s) at [\(removals.map(String.init).joined(separator: ", "))]" as String,
			"- mutated \(mutations.count) item(s) at [\(mutations.map(String.init).joined(separator: ", "))]" as String,
			"- moved \(moves.count) item(s) at [\(moves.map(moveDescription).joined(separator: ", "))]" as String,
		] as [String]).joined(separator: "\n")
	}
}
