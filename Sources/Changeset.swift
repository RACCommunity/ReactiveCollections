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

	public init<C: Collection, Identifier: Hashable>(
		previous: C,
		current: C,
		identifier: (C.Iterator.Element) -> Identifier,
		areEqual: (C.Iterator.Element, C.Iterator.Element) -> Bool
	) where C.Index == C.Indices.Iterator.Element {
		var table: [Identifier: DiffEntry] = Dictionary(minimumCapacity: Int(current.count))
		var oldReferences: [DiffReference] = []
		var newReferences: [DiffReference] = []

		oldReferences.reserveCapacity(Int(previous.count))
		newReferences.reserveCapacity(Int(current.count))

		func tableEntry(for identifier: Identifier) -> DiffEntry {
			if let index = table.index(forKey: identifier) {
				return table[index].value
			}

			let entry = DiffEntry()
			table[identifier] = entry
			return entry
		}

		// Pass 1: Scan the new snapshot.
		for element in current {
			let key = identifier(element)
			let entry = tableEntry(for: key)

			entry.occurenceInNew += 1
			newReferences.append(.table(entry))
		}

		// Pass 2: Scan the old snapshot.
		for (offset, index) in previous.indices.enumerated() {
			let key = identifier(previous[index])
			let entry = tableEntry(for: key)

			entry.occurenceInOld += 1
			entry.locationInOld = offset
			oldReferences.append(.table(entry))
		}

		// Pass 3: Single-occurence lines
		for newPosition in newReferences.startIndex ..< newReferences.endIndex {
			switch newReferences[newPosition] {
			case let .table(entry):
				if entry.occurenceInNew == 1 && entry.occurenceInNew == entry.occurenceInOld {
					let oldPosition = entry.locationInOld!
					newReferences[newPosition] = .remote(oldPosition)
					oldReferences[oldPosition] = .remote(newPosition)
				}

			case .remote:
				break
			}
		}

		self.init()

		// Pass 4: Compute inserts, removals and mutations. Prepare move statistics.
		for oldPosition in 0 ..< oldReferences.endIndex {
			if case .table = oldReferences[oldPosition] {
				removals.insert(oldPosition)
			}
		}

		var moveSources = IndexSet()
		var moveDestinations = IndexSet()

		// Pass 5: Compute removals and position-invariant mutations, and prepare move satistics.
		for newPosition in newReferences.indices {
			switch newReferences[newPosition] {
			case .table:
				inserts.insert(newPosition)

			case let .remote(oldPosition):
				guard oldPosition == newPosition else {
					moveSources.insert(oldPosition)
					moveDestinations.insert(newPosition)
					continue
				}

				let previousIndex = previous.index(previous.startIndex, offsetBy: C.IndexDistance(oldPosition))
				let currentIndex = current.index(current.startIndex, offsetBy: C.IndexDistance(newPosition))

				if !areEqual(previous[previousIndex], current[currentIndex]) {
					mutations.insert(newPosition)
				}
			}
		}

		// Pass 6: Bucket moves.
		var bucket: [Int: Set<Path>] = [:]

		for newPosition in newReferences.indices {
			if case let .remote(oldPosition) = newReferences[newPosition] {
				if oldPosition != newPosition {
					let stepSize = newPosition - oldPosition
					let precedingInserts = inserts.count(in: 0 ..< newPosition)

					guard stepSize != precedingInserts else {
						continue
					}

					let precedingRemovals = removals.count(in: 0 ..< oldPosition)

					guard stepSize != -precedingRemovals else {
						continue
					}

					bucket.insert(Path(source: oldPosition, destination: newPosition),
					              postRemovalStepSize: abs(stepSize + precedingRemovals))
				}
			}
		}

		// Pass 7: Process moves.
		var stepSizes = IndexSet(bucket.keys)
		print("step sizes: \(Array(stepSizes))")

		for bucketStepSize in stepSizes.reversed() {
			assert(bucketStepSize > 0)
			print("resolving bucket of post removal step size \(bucketStepSize)")

			while !bucket[bucketStepSize]!.isEmpty {
				let path = bucket[bucketStepSize]!.removeFirst()
				let isForward = path.destination - path.source > 0

				if isForward {
					// Forward
					let precedingInserts = inserts.count(in: 0 ..< path.source)
					let precedingRemovals = removals.count(in: 0 ..< path.source)
					let overlappingInserts = inserts.count(in: path.source ..< path.destination)

					var searchStart = path.source + precedingInserts - precedingRemovals
					var searchIndex = path.destination - 1
					var stepSizeOffset = -precedingRemovals + overlappingInserts

					print("resolving \(path.source) -> \(path.destination); forward")
					print("initial: \(searchStart) ... \(searchIndex); offset = \(stepSizeOffset); stepSize = \(-1 + stepSizeOffset)")

					func debug(_ title: StaticString, _ additionalContext: String?) {
						print(String(format: "%@itr=%3d...%3d; stepSizeOffset=%3d; stepSize=%3d",
						             String(describing: title)
										.replacingOccurrences(of: " ", with: "_")
										.appending(": ")
										.appending(additionalContext.map { $0 + "; " } ?? "")
										.padding(toLength: 40, withPad: " ", startingAt: 0),
						             searchStart,
						             searchIndex,
						             stepSizeOffset,
						             -1 + stepSizeOffset))
					}

					var elidableSourceLowerBound = -1

					while searchIndex - searchStart >= 0 && searchIndex >= 0 {
						defer {
							searchIndex -= 1

							if searchIndex < path.source && removals.contains(searchIndex) {
								searchStart -= 1
								debug("expand search", "overlappingRemoval=\(searchIndex)")
							}
						}

						if searchIndex >= path.source && removals.contains(searchIndex) {
							stepSizeOffset -= 1
							debug("expand step size", "overlappingRemoval=\(searchIndex)")
						}

						switch newReferences[searchIndex] {
						case .table:
							stepSizeOffset -= 1
							searchStart -= 1
							debug("skip", "insertion")

						case let .remote(oldPosition):
							let localStepSize = searchIndex - oldPosition

							guard localStepSize != 0 else {
								elidableSourceLowerBound = max(elidableSourceLowerBound, oldPosition)
								debug("not moved", "elidableLB=\(elidableSourceLowerBound)")
								continue
							}

							guard localStepSize < 0 else {
								// Ignore any moves in the same direction.
								// Treat as an insertion.
								stepSizeOffset -= 1
								searchStart -= 1
								elidableSourceLowerBound = max(elidableSourceLowerBound, searchIndex)
								debug("skip", "same_direction; path=\(oldPosition)->\(searchIndex); elidableLB=\(elidableSourceLowerBound)")
								break
								
							}

							guard localStepSize == -1 + stepSizeOffset else {
								// Ignore any moves that wasn't of the expected dependent move
								// step size.
								debug("skip", "localStepSize=\(localStepSize)")
								break
							}

							guard !(searchIndex ... oldPosition).contains(elidableSourceLowerBound) else {
								debug("skip", "elidableLB=\(elidableSourceLowerBound)")
								break
							}

							if case let .remote(newLocForPrevious) = oldReferences[oldPosition - 1],
							   newLocForPrevious >= searchIndex,
							   abs(newLocForPrevious - oldPosition + 1) >= abs(localStepSize) {
								debug("skip", "criticalMove")
								break
							}

							bucket.remove(Path(source: oldPosition, destination: searchIndex),
							              postRemovalStepSize: abs(localStepSize + removals.count(in: 0 ..< oldPosition)))

							debug("elide", "path=\(oldPosition)->\(searchIndex)")

							let previousIndex = previous.index(previous.startIndex, offsetBy: C.IndexDistance(oldPosition))
							let currentIndex = current.index(current.startIndex, offsetBy: C.IndexDistance(searchIndex))

							if !areEqual(previous[previousIndex], current[currentIndex]) {
								mutations.insert(oldPosition)
							}
						}
					}
				} else {
					// Backward
					let precedingInserts = inserts.count(in: 0 ..< path.destination)

					var searchIndex = path.destination + 1
					var searchEnd = path.source + precedingInserts
					var stepSizeOffset = precedingInserts

					print("resolving \(path.source) -> \(path.destination); backward")
					print("initial: \(searchIndex) ... \(searchEnd); offset = \(stepSizeOffset); stepSize = \(1 + stepSizeOffset)")

					func debug(_ title: StaticString, _ additionalContext: String?) {
						print(String(format: "%@itr=%3d...%3d; stepSizeOffset=%3d; stepSize=%3d",
						             String(describing: title)
										.replacingOccurrences(of: " ", with: "_")
										.appending(": ")
										.appending(additionalContext.map { $0 + "; " } ?? "")
										.padding(toLength: 40, withPad: " ", startingAt: 0),
						             searchIndex,
						             searchEnd,
						             stepSizeOffset,
						             1 + stepSizeOffset))
					}

					var elidableSourceLowerBound = -1

					let cap = newReferences.count
					while searchEnd - searchIndex >= 0 && searchIndex < cap {
						defer {
							if searchIndex < path.source {
								if removals.contains(searchIndex - 1) {
									stepSizeOffset -= 1
									searchEnd -= 1
									debug("contract search", "overlappingRemoval=\(searchIndex - 1)")
								}
							}

							searchIndex += 1
						}

						switch newReferences[searchIndex] {
						case .table:
							stepSizeOffset += 1
							searchEnd += 1
							debug("skip", "insertion")

						case let .remote(oldPosition):
							let localStepSize = searchIndex - oldPosition

							guard localStepSize != 0 else {
								elidableSourceLowerBound = max(elidableSourceLowerBound, oldPosition)
								debug("not moved", "elidableSourceLowerBound=\(elidableSourceLowerBound)")
								continue
							}

							guard localStepSize > 0 else {
								// Ignore any moves in the same direction.
								// Treat as an insertion.
								stepSizeOffset += 1
								searchEnd += 1
								debug("skip", "same_direction; path=\(oldPosition)->\(searchIndex)")
								break
							}

							guard localStepSize == 1 + stepSizeOffset else {
								// Ignore any moves that wasn't of the expected dependent move
								// step size.
								debug("skip", "localStepSize=\(localStepSize)")
								break
							}

							guard oldPosition >= elidableSourceLowerBound else {
								debug("skip", "elidableSourceLowerBound=\(elidableSourceLowerBound)")
								break
							}

							bucket.remove(Path(source: oldPosition, destination: searchIndex),
							              postRemovalStepSize: abs(localStepSize + removals.count(in: 0 ..< oldPosition)))

							debug("elide", "path=\(oldPosition)->\(searchIndex)")

							let previousIndex = previous.index(previous.startIndex, offsetBy: C.IndexDistance(oldPosition))
							let currentIndex = current.index(current.startIndex, offsetBy: C.IndexDistance(searchIndex))

							if !areEqual(previous[previousIndex], current[currentIndex]) {
								mutations.insert(oldPosition)
							}
						}
					}
				}

				let previousIndex = previous.index(previous.startIndex, offsetBy: C.IndexDistance(path.source))
				let currentIndex = current.index(current.startIndex, offsetBy: C.IndexDistance(path.destination))

				moves.append(Changeset.Move(source: path.source,
				                            destination: path.destination,
				                            isMutated: !areEqual(previous[previousIndex], current[currentIndex])))
			}
		}
	}
}

extension Changeset.Move {
	fileprivate var stepSize: Int {
		return destination - source
	}
}

private func sign(_ i: Int) -> Bool {
	return i >= 0 ? true : false
}

private struct Path: Hashable {
	let source: Int
	let destination: Int

	var hashValue: Int {
		return (source + destination) / 2
	}

	static func ==(lhs: Path, rhs: Path) -> Bool {
		return lhs.source == rhs.source && lhs.destination == rhs.destination
	}
}

extension Dictionary where Key == Int, Value == Set<Path> {
	fileprivate mutating func remove(_ path: Path, postRemovalStepSize stepSize: Int) {
		self[stepSize]?.remove(path)
	}

	fileprivate mutating func insert(_ path: Path, postRemovalStepSize stepSize: Int) {
		if index(forKey: stepSize) == nil {
			self[stepSize] = []
		}

		self[stepSize]!.insert(path)
	}
}

// The key equality implies only referential equality. But the value equality of the
// uniquely identified element across snapshots is uncertain. It is pretty common to diff
// elements with constant unique identifiers but changing contents. For example, we may
// have an array of `Conversation`s, identified by the backend ID, that is constantly
// updated with the latest messages pushed from the backend. So our diffing algorithm
// must have an additional mean to test elements for value equality.

private final class DiffEntry {
	var occurenceInOld = 0
	var occurenceInNew = 0
	var locationInOld: Int?
}

private enum DiffReference {
	case remote(Int)
	case table(DiffEntry)
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
