import Foundation

/// `Delta` represents an atomic batch of changes applied to a collection.
public struct Delta<ChangeRepresentation: Collection> {
	public let inserts: ChangeRepresentation
	public let deletes: ChangeRepresentation

	public init(inserts: ChangeRepresentation, deletes: ChangeRepresentation) {
		self.inserts = inserts
		self.deletes = deletes
	}
}

extension Delta where ChangeRepresentation: ExpressibleByArrayLiteral {
	public init(inserts: ChangeRepresentation = [], deletes: ChangeRepresentation = []) {
		self.inserts = inserts
		self.deletes = deletes
	}
}

extension Delta where ChangeRepresentation: Equatable {
	public static func ==(lhs: Delta<ChangeRepresentation>, rhs: Delta<ChangeRepresentation>) -> Bool {
		return lhs.inserts == rhs.inserts &&
			lhs.deletes == rhs.deletes
	}
}

extension Delta: CustomDebugStringConvertible {
	public var debugDescription: String {
		return "inserts: \(inserts); deletes: \(deletes)"
	}
}

// FIXME: Swift 4 Conditional Conformance
//
// Remove the protocol after `CountableRange` is folded into `Range`.
public protocol RangeProtocol {
	associatedtype Bound

	var lowerBound: Bound { get }
	var upperBound: Bound { get }
}

extension Range: RangeProtocol {}
extension CountableRange: RangeProtocol {}

// FIXME: Swift collection model future enhancements
//
// This would be replaced by the `Segments` associated type of
// `IndexingDelta.ChangeRepresentation`.
//
// https://bugs.swift.org/browse/SR-3633
public protocol RangeRepresentableCollection: Collection {
	// FIXME: Swift 4 Associated Type Constraints
	//
	// associatedtype RangeRepresentation: Collection where RangeRepresentation.Element == Range<Element>
	associatedtype RangeRepresentation: Collection

	// FIXME: Swift 4 Associated Type Constraints
	//
	// associatedtype Iterator where Iterator.Element: Comparable

	var ranges: RangeRepresentation { get }
}

extension IndexSet: RangeRepresentableCollection {
	public var ranges: RangeView {
		return rangeView
	}
}

/// `IndexingDelta` is an abstraction for describing an atomic batch of changes applied to
/// a collection with a stable element order.
///
/// The protocol requires conforming types to guarantee a stable order of elements across
/// deltas, such that consumers of the delta may safely derive integer offsets from the
/// indices. In other words, given index *I* of delta *A* and index *J* of delta *B*
/// referring to a certain position *P*, the derived offset of both index *I* and *J* must
/// equal, provided that *P* has not been affected by any insertions or removals.
///
/// While the protocol supports `Collection` and `BidirectionalCollection`, it is expected
/// to be most performant with the O(1) index manipulation guarantee of
/// `RandomAccessCollection`.
///
/// Support of move operations is not mandatory. Source collections of may choose to
/// represent it as a delete offset and an insert offset, if it is expected to be more
/// performant, e.g. for `Collection` and `BidirectionalCollection`.
public protocol IndexingDelta {
	associatedtype Snapshot: Collection

	// FIXME: Swift 4 Associated Type Constraints
	//
	// associatedtype ChangeRepresentation: Collection where ChangeRepresentation.Element == Snapshot.Index
	associatedtype ChangeRepresentation: Collection

	// FIXME: Swift 4 Associated Type Constraints
	//
	// associatedtype IndexPairs: Collection where IndexPairs.Element == (Snapshot.Index, Snapshot.Index)
	associatedtype IndexPairs: Collection = EmptyCollection<(Snapshot.Index, Snapshot.Index)>

	/// The collection prior to the changes.
	var previous: Snapshot { get }

	/// The collection after the changes.
	var current: Snapshot { get }

	/// The indices of insertions made to the collection. The indices should be based on
	/// the order after deletions are applied.
	var inserts: ChangeRepresentation { get }

	/// The indices of deletions made to the collection. The indices should be based on
	/// the original order, or in other words ignore all insertions.
	var deletes: ChangeRepresentation { get }

	/// The indices of updates made to the collection. The indices should be based on
	/// the original order, or in other words ignore all insertions.
	var updates: ChangeRepresentation { get }

	/// The pairs of indices that represent moves made to the collection. The first
	/// index is the source, and the second is the destination. The source index abides to
	/// the same requirement as a delete, whereas the destination index abides to the same
	/// requirement as an insert.
	///
	/// - note: This is an optional requirement. If a conforming type does not wish to
	///         implement move tracking, it may emit any equivalent combination of
	///         inserts, deletes and updates.
	var moves: IndexPairs { get }

	static func computeOffsets(for indices: ChangeRepresentation, in collection: Snapshot) -> IndexSet

	static func computeOffsetPairs(from indexPairs: IndexPairs, in collections: (Snapshot, Snapshot)) -> [(Int, Int)]
}

extension IndexingDelta {
	public var moves: EmptyCollection<(Snapshot.Index, Snapshot.Index)> {
		return EmptyCollection()
	}
}

extension IndexingDelta where Snapshot.Iterator.Element: Equatable, ChangeRepresentation: Equatable, IndexPairs.Iterator.Element == (Snapshot.Index, Snapshot.Index) {
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.previous == rhs.previous &&
			lhs.current == rhs.current &&
			lhs.inserts == rhs.inserts &&
			lhs.deletes == rhs.deletes &&
			lhs.updates == rhs.updates &&
			lhs.moves == rhs.moves
	}
}

/// `ArrayDelta` represents an atomic batch of changes applied to an array.
public struct ArrayDelta<Snapshot: Collection>: IndexingDelta where Snapshot.Index == Int, Snapshot.IndexDistance.Stride: SignedInteger {
	public typealias ChangeRepresentation = IndexSet

	public let previous: Snapshot
	public let current: Snapshot

	public let inserts: IndexSet
	public let deletes: IndexSet
	public let updates: IndexSet
	public let moves: [(Int, Int)]

	public init(previous: Snapshot, current: Snapshot, inserts: IndexSet = [], deletes: IndexSet = [], updates: IndexSet = [], moves: [(Int, Int)] = []) {
		self.previous = previous
		self.current = current
		self.inserts = inserts
		self.deletes = deletes
		self.updates = updates
		self.moves = moves
	}
}

extension ArrayDelta: CustomDebugStringConvertible {
	public var debugDescription: String {
		return "previous: \(previous.count) element(s)\n>> \(previous)\ncurrent: \(current.count) element(s)\n>> \(current)\ninserts: \(inserts.count)\n>> \(Array(inserts))\ndeletes: \(deletes.count)\n>> \(Array(deletes))\nupdates: \(updates.count)\n>> \(Array(updates))\nmoves: \(moves.count)\n>> \(Array(moves))"
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

extension IndexingDelta where ChangeRepresentation.Iterator.Element: Comparable, Snapshot.Index == ChangeRepresentation.Iterator.Element, Snapshot.IndexDistance.Stride: SignedInteger {
	public static func computeOffsets(for indices: ChangeRepresentation, in collection: Snapshot) -> IndexSet {
		var iteratingIndex = collection.startIndex
		var indexSet = IndexSet()
		for index in indices {
			let distance = collection.distance(from: iteratingIndex, to: index)
			iteratingIndex = index
			indexSet.insert(Int(distance.toIntMax()))
		}
		return indexSet
	}
}

extension IndexingDelta where ChangeRepresentation.Iterator.Element: Comparable, ChangeRepresentation: RangeRepresentableCollection, ChangeRepresentation.RangeRepresentation.Iterator.Element: RangeProtocol, ChangeRepresentation.RangeRepresentation.Iterator.Element.Bound == ChangeRepresentation.Iterator.Element, Snapshot.Index == ChangeRepresentation.Iterator.Element, Snapshot.IndexDistance.Stride: SignedInteger {
	public static func computeOffsets(for indices: ChangeRepresentation, in collection: Snapshot) -> IndexSet {
		var indexSet = IndexSet()
		indices.ranges
			.map { range -> CountableRange<Int> in
				let start = collection.distance(from: collection.startIndex, to: range.lowerBound)
				let end = collection.distance(from: range.lowerBound, to: range.upperBound)
				return Int(start.toIntMax()) ..< Int((start + end).toIntMax())
			}
			.forEach { indexSet.insert(integersIn: $0) }
		return indexSet
	}
}

extension IndexingDelta where IndexPairs.Iterator.Element == (Snapshot.Index, Snapshot.Index) {
	public static func computeOffsetPairs(from indexPairs: IndexPairs, in collections: (Snapshot, Snapshot)) -> [(Int, Int)] {
		return indexPairs.map { indices in
			return (Int(collections.0.distance(from: collections.0.startIndex, to: indices.0).toIntMax()),
			        Int(collections.1.distance(from: collections.1.startIndex, to: indices.1).toIntMax()))
		}
	}
}
