import Foundation

/// Represents an atomic batch of changes made to a collection.
///
/// A `Changeset` represents changes as **offsets** of elements. You may
/// subscript a collection of zero-based indexing with the offsets, e.g. `Array`. You must
/// otherwise convert the offsets into indices before subscripting.
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

	/// The offsets of inserted elements **after** the removals were applied.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the current snapshot, the
	///              start index and the offset.
	public var inserts = IndexSet()

	/// The offsets of removed elements **prior to** any changes being applied.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the previous snapshot, the
	///              start index and the offset.
	public var removals = IndexSet()

	/// The offsets of position-invariant mutations.
	///
	/// `mutations` only implies an invariant relative position. The actual indexes can
	/// be different, depending on the collection type.
	///
	/// If an element has both changed and moved, it would be included in `moves` with an
	/// asserted mutation flag.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the relevant snapshot, the
	///              start index and the offset.
	public var mutations = IndexSet()

	/// The offset pairs of moves with a mutation flag as the associated value.
	///
	/// - important: To obtain the actual index, you must apply
	///              `Collection.index(self:_:offsetBy:)` on the relevant snapshot, the
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
