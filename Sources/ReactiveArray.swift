import Foundation
import ReactiveSwift
import Result

public final class ReactiveArray<Element>: RandomAccessCollection {
	public typealias Snapshot = ContiguousArray<Element>
	public typealias Change = Delta<Snapshot, IndexSet>

	fileprivate let storage: Storage<ContiguousArray<Element>>
	fileprivate let observer: Observer<Change, NoError>

	public let signal: Signal<Change, NoError>
	public var producer: SignalProducer<Change, NoError> {
		return SignalProducer { [weak self, storage] observer, disposable in
			storage.modify { elements in
				let delta = Delta(previous: [],
				                  current: elements,
				                  inserts: IndexSet(integersIn: elements.indices),
				                  deletes: [],
				                  updates: [])
				observer.send(value: delta)

				if let strongSelf = self {
					disposable += strongSelf.signal.observe(observer)
				} else {
					observer.sendCompleted()
				}
			}
		}
	}

	public var startIndex: Int {
		return storage.elements.startIndex
	}

	public var endIndex: Int {
		return storage.elements.endIndex
	}

	public subscript(position: Int) -> Element {
		return storage.elements[position]
	}

	public init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
		(signal, observer) = Signal<Change, NoError>.pipe()
		storage = Storage(ContiguousArray(sequence))
	}

	public convenience init() {
		self.init([])
	}

	public func modify<Result>(_ action: (inout MutableView) -> Result) -> Result {
		return storage.modify { elements in
			var view = MutableView(elements)
			let result = action(&view)

			let delta = Change(previous: elements, current: view.elements, inserts: view.inserts, deletes: view.deletes, updates: view.updates)
			elements = view.elements

			observer.send(value: delta)

			return result
		}
	}

	deinit {
		observer.sendCompleted()
	}
}

extension ReactiveArray: ExpressibleByArrayLiteral {
	public convenience init(arrayLiteral elements: Element...) {
		self.init(elements)
	}
}

extension ReactiveArray where Element: Equatable {
	public static func ==<C: Collection>(left: ReactiveArray<Element>, right: C) -> Bool where C.Iterator.Element == Element {
		return left.elementsEqual(right, by: ==)
	}
}

extension ReactiveArray {
	public struct MutableView: RandomAccessCollection, MutableCollection {
		fileprivate var elements: ContiguousArray<Element>

		// Indices of insertions made to `elements`.
		fileprivate var inserts: IndexSet

		// Indices of deletions made to `elements`, ignoring the insertions.
		fileprivate var deletes: IndexSet

		// Indices of updates made to `elements`, ignoring the insertions.
		fileprivate var updates: IndexSet

		fileprivate init(_ elements: ContiguousArray<Element>) {
			self.elements = elements
			inserts = []
			deletes = []
			updates = []
		}

		public mutating func replaceSubrange<C>(_ subrange: CountableRange<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Element {
			elements.replaceSubrange(subrange, with: newElements)

			let elementsCount = Int(newElements.count.toIntMax())

			if subrange.count > elementsCount {
				let deleteCount = subrange.count - elementsCount
				let deleteRange = (subrange.upperBound - deleteCount) ..< subrange.upperBound
				let updateRange = subrange.lowerBound ..< deleteRange.lowerBound

				if !updateRange.isEmpty {
					var newUpdates = IndexSet(integersIn: updateRange)

					// Handle updates to insertions.
					newUpdates.subtract(inserts)

					// Record the update set.
					updates.formUnion(newUpdates.ignoringInserts(inserts))
				}

				if !deleteRange.isEmpty {
					var newDeletes = IndexSet(integersIn: deleteRange)

					// Handle the deletion of insertions.
					let uncommittedInsertDeletes = inserts.intersection(newDeletes)
					inserts.subtract(uncommittedInsertDeletes)
					newDeletes.subtract(uncommittedInsertDeletes)

					// Record the delete set and update set.
					newDeletes = newDeletes.ignoringInserts(inserts)
					deletes.formUnion(newDeletes)
					updates.subtract(newDeletes)
				}
			} else {
				let insertCount = elementsCount - subrange.count
				let insertRange = subrange.upperBound ..< (subrange.upperBound + insertCount)
				let updateRange = subrange

				if !updateRange.isEmpty {
					var newUpdates = IndexSet(integersIn: updateRange)

					// Handle updates to insertions.
					newUpdates.subtract(inserts)

					// Record the update set.
					updates.formUnion(newUpdates.ignoringInserts(inserts))
				}

				if !insertRange.isEmpty {
					var newInserts = IndexSet(integersIn: insertRange)

					// Record the insert set.
					newInserts.formUnion(inserts.shifted(byInserts: newInserts))
					inserts = newInserts
				}
			}
		}

		public var startIndex: Int {
			return elements.startIndex
		}

		public var endIndex: Int {
			return elements.endIndex
		}

		public subscript(position: Int) -> Element {
			get {
				return elements[position]
			}
			set {
				replaceSubrange(position ..< position + 1, with: CollectionOfOne(newValue))
			}
		}

		public mutating func append(_ element: Element) {
			replaceSubrange(endIndex ..< endIndex, with: CollectionOfOne(element))
		}

		public mutating func append<C: Collection>(contentsOf elements: C) where C.Iterator.Element == Element {
			replaceSubrange(endIndex ..< endIndex, with: elements)
		}

		public mutating func insert(_ element: Element, at position: Int) {
			replaceSubrange(position ..< position, with: CollectionOfOne(element))
		}

		public mutating func insert<C: Collection>(contentsOf elements: C, at position: Int) where C.Iterator.Element == Element {
			replaceSubrange(position ..< position, with: elements)
		}

		@discardableResult
		public mutating func remove(at position: Int) -> Element {
			let value = self[position]
			replaceSubrange(position ..< position + 1, with: EmptyCollection())
			return value
		}

		public mutating func removeAll(keepingCapacity: Bool = false) {
			replaceSubrange(startIndex ..< endIndex, with: EmptyCollection())
		}

		public mutating func removeFirst(_ n: Int) {
			precondition(n <= count, "Index out of bound.")
			replaceSubrange(0 ..< n, with: EmptyCollection())
		}

		@discardableResult
		public mutating func removeFirst() -> Element {
			return remove(at: 0)
		}

		public mutating func removeLast(_ n: Int) {
			precondition(n <= count, "Index out of bound.")
			replaceSubrange(endIndex - n ..< endIndex, with: EmptyCollection())
		}

		@discardableResult
		public mutating func removeLast() -> Element {
			return remove(at: endIndex - 1)
		}

		public mutating func swap(_ source: Int, with destination: Int) {
			// FIXME: Emit a move index pair instead of updates.
			Swift.swap(&self[source], &self[destination])
		}

		public mutating func removeSubrange(_ subrange: Range<Int>) {
			replaceSubrange(subrange, with: EmptyCollection())
		}

		public mutating func removeSubrange(_ subrange: ClosedRange<Int>) {
			replaceSubrange(subrange, with: EmptyCollection())
		}

		public mutating func removeSubrange(_ subrange: CountableRange<Int>) {
			replaceSubrange(subrange, with: EmptyCollection())
		}

		public mutating func removeSubrange(_ subrange: CountableClosedRange<Int>) {
			replaceSubrange(subrange, with: EmptyCollection())
		}

		public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Element {
			replaceSubrange(CountableRange(subrange), with: newElements)
		}

		public mutating func replaceSubrange<C>(_ subrange: ClosedRange<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Element {
			replaceSubrange(CountableRange(subrange), with: newElements)
		}

		public mutating func replaceSubrange<C>(_ subrange: CountableClosedRange<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Element {
			replaceSubrange(CountableRange(subrange), with: newElements)
		}
	}
}

extension ReactiveArray: CustomDebugStringConvertible {
	public var debugDescription: String {
		return storage.elements.description
	}
}

extension IndexSet {
	fileprivate func ignoringInserts(_ indices: IndexSet) -> IndexSet {
		var shifted = IndexSet()

		for i in self {
			shifted.insert(i - indices.count(in: 0 ... i))
		}

		return shifted
	}

	fileprivate func shifted(byInserts indices: IndexSet) -> IndexSet {
		var shifted = IndexSet()

		for i in self {
			shifted.insert(i + indices.count(in: 0 ... i))
		}

		return shifted
	}
}

private final class Storage<Elements> {
	private var _elements: Elements

	var elements: Elements {
		get { return _elements }
		set {
			writeLock.lock()
			_elements = newValue
			writeLock.unlock()
		}
	}

	/// A lock to protect mutations and their subsequent event emission. Reads do
	/// not need to be protected, since the copy-on-write already guards reads.
	/// The producer, however, has to acquire the lock to block new mutations
	/// before it observes the delta signal.
	fileprivate let writeLock: NSLock

	init(_ elements: Elements) {
		self._elements = elements

		writeLock = NSLock()
		writeLock.name = "org.RACCommunity.ReactiveCollections.ReactiveArray.writeLock"
	}

	func modify<Result>(_ action: (inout Elements) throws -> Result) rethrows -> Result {
		writeLock.lock()
		let returnValue = try action(&_elements)
		writeLock.unlock()
		return returnValue
	}
}
