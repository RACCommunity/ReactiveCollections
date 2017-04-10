import Foundation

public protocol ArrayDeltaProtocol: DeltaProtocol {
	var moves: [(source: Elements.Index, destination: Elements.Index)] { get }
}

public protocol DeltaProtocol {
	associatedtype Elements: Collection
	associatedtype ChangeRepresentation

	var previous: Elements { get }
	var current: Elements { get }

	var inserts: ChangeRepresentation { get }
	var deletes: ChangeRepresentation { get }
	var updates: ChangeRepresentation { get }
}

public class ArrayDelta<Elements: RandomAccessCollection>: Delta<Elements, IndexSet>, ArrayDeltaProtocol where Elements.Index == Int {
	public final let moves: [(source: Int, destination: Int)]

	public init(
		previous: Elements,
		current: Elements,
		inserts: IndexSet = [],
		deletes: IndexSet = [],
		updates: IndexSet = [],
		moves: [(source: Elements.Index, destination: Elements.Index)] = []
	) {
		self.moves = moves
		super.init(previous: previous, current: current, inserts: inserts, deletes: deletes, updates: updates)
	}
}

public class Delta<Elements: Collection, ChangeRepresentation: Collection>: DeltaProtocol {
	public final let previous: Elements
	public final let current: Elements

	public final let inserts: ChangeRepresentation
	public final let deletes: ChangeRepresentation
	public final let updates: ChangeRepresentation

	public init(
		previous: Elements,
		current: Elements,
		inserts: ChangeRepresentation,
		deletes: ChangeRepresentation,
		updates: ChangeRepresentation
	) {
		self.previous = previous
		self.current = current
		self.inserts = inserts
		self.deletes = deletes
		self.updates = updates
	}
}

extension Delta where Elements.Iterator.Element: Equatable, ChangeRepresentation: Equatable {

	public static func ==(lhs: Delta<Elements, ChangeRepresentation>, rhs: Delta<Elements, ChangeRepresentation>) -> Bool {

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

		return zip(lhs, rhs).first(where: !=) == nil
	}
}
