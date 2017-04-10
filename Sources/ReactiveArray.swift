import Foundation
import ReactiveSwift
import Result

public final class ReactiveArray<Element> {
	public typealias Snapshot = ContiguousArray<Element>
	public typealias Change = Delta<Snapshot, IndexSet>

	fileprivate let storage: Storage<ContiguousArray<Element>>

	public let signal: Signal<Change, NoError>
	fileprivate let innerObserver: Observer<Change, NoError>

	public init(_ elements: [Element]) {
		(signal, innerObserver) = Signal<Change, NoError>.pipe()
		storage = Storage(ContiguousArray(elements))
	}

	public convenience init() {
		self.init([])
	}

	deinit {
		innerObserver.sendCompleted()
	}

}

extension ReactiveArray {

	public var producer: SignalProducer<Change, NoError> {
		return SignalProducer { [weak self, storage] observer, disposable in
			storage.modify { elements in
				let delta = Delta(previous: [],
				                  current: elements,
				                  inserts: IndexSet(integersIn: elements.indices),
				                  deletes: .empty,
				                  updates: .empty)
				observer.send(value: delta)

				if let strongSelf = self {
					disposable += strongSelf.signal.observe(observer)
				} else {
					observer.sendCompleted()
				}
			}
		}
	}
}

// MARK: - ExpressibleByArrayLiteral

extension ReactiveArray: ExpressibleByArrayLiteral {

	public convenience init(arrayLiteral elements: Element...) {
		self.init(elements)
	}
}

// MARK: - MutableCollection

extension ReactiveArray: MutableCollection {

	public var startIndex: Int {
		return storage.elements.startIndex
	}

	public var endIndex: Int {
		return storage.elements.endIndex
	}

	public subscript(position: Int) -> Element {
		get {
			return storage.elements[position]
		}
		set {
			replaceSubrange(position..<index(after: position), with: CollectionOfOne(newValue))
		}
	}

	public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
		get {
			return storage.elements[bounds]
		}
		set {
			replaceSubrange(bounds, with: newValue)
		}
	}
}

// MARK: - RandomAccessCollection

extension ReactiveArray: RandomAccessCollection {

	public typealias Indices = CountableRange<Int>
}

// MARK: - RangeReplaceableCollection

extension ReactiveArray: RangeReplaceableCollection {

	public convenience init(repeating repeatedValue: Element, count: Int) {
		self.init(Array(repeating: repeatedValue, count: count))
	}

	public func append(_ newElement: Element) {
		insert(newElement, at: endIndex)
	}

	public func append<S : Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
		reserveCapacity(count + newElements.underestimatedCount)
		insert(contentsOf: Array(newElements), at: endIndex)
	}

	public func insert(_ newElement: Element, at i: Int) {
		replaceSubrange(i..<i, with: CollectionOfOne(newElement))
	}

	public func insert<C : Collection>(contentsOf newElements: C, at i: Int) where C.Iterator.Element == Element {
		replaceSubrange(i..<i, with: newElements)
	}

	public func remove(at position: Int) -> Element {
		precondition(!isEmpty, "can't remove from an empty array")

		return storage.modify { elements in
			let previous = elements
			let value = previous[position]
			elements.remove(at: position)

			let delta = Delta(previous: previous,
			                  current: elements,
			                  inserts: .empty,
			                  deletes: IndexSet(integer: position),
			                  updates: .empty)
			innerObserver.send(value: delta)

			return value
		}
	}

	public func removeAll(keepingCapacity keepCapacity: Bool = false) {
		if keepCapacity {
			removeSubrange(indices)
		} else {
			storage.modify { elements in
				let previous = storage.elements
				elements.removeAll()

				let delta = Delta(previous: previous,
				                  current: elements,
				                  inserts: .empty,
				                  deletes: IndexSet(integersIn: previous.indices),
				                  updates: .empty)
				innerObserver.send(value: delta)
			}
		}
	}

	public func removeFirst() -> Element {
		precondition(!isEmpty, "can't remove first element from an empty array")
		return remove(at: startIndex)
	}

	public func removeFirst(_ n: Int) {
		precondition(n >= 0, "number of elements to remove should be non-negative")
		precondition(n <= count, "can't remove more items from an array than it has")
		removeSubrange(startIndex..<startIndex.advanced(by: n))
	}

	public func removeLast() -> Element {
		precondition(!isEmpty, "can't remove last element from an empty array")
		return remove(at: index(before: endIndex))
	}

	public func removeLast(_ n: Int) {
		precondition(n >= 0, "number of elements to remove should be non-negative")
		precondition(n <= count, "can't remove more items from an array than it has")
		removeSubrange(endIndex.advanced(by: -n)..<endIndex)
	}

	public func removeSubrange(_ bounds: ClosedRange<Int>) {
		replaceSubrange(bounds, with: EmptyCollection())
	}

	public func removeSubrange(_ bounds: CountableRange<Int>) {
		replaceSubrange(bounds, with: EmptyCollection())
	}

	public func removeSubrange(_ bounds: CountableClosedRange<Int>) {
		replaceSubrange(bounds, with: EmptyCollection())
	}

	public func removeSubrange(_ bounds: Range<Int>) {
		replaceSubrange(bounds, with: EmptyCollection())
	}

	public func replaceSubrange<C>(_ subrange: ClosedRange<Int>, with newElements: C) where C : Collection, C.Iterator.Element == Element {
		replaceSubrange(Range(subrange), with: newElements)
	}

	public func replaceSubrange<C>(_ subrange: CountableRange<Int>, with newElements: C) where C : Collection, C.Iterator.Element == Element {
		replaceSubrange(Range(subrange), with: newElements)
	}

	public func replaceSubrange<C>(_ subrange: CountableClosedRange<Int>, with newElements: C) where C : Collection, C.Iterator.Element == Element {
		replaceSubrange(Range(subrange), with: newElements)
	}

	public func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Element {
		storage.modify { elements in
			let previous = elements

			elements.replaceSubrange(subrange, with: newElements)

			let insertsUpperBound = subrange.lowerBound.advanced(by: Int(newElements.distance(from: newElements.startIndex, to: newElements.endIndex).toIntMax()))
			let inserts = IndexSet(integersIn: subrange.lowerBound ..< insertsUpperBound)
			let deletes = IndexSet(integersIn: subrange)
			let updates = inserts.intersection(deletes)

			let delta = Delta(previous: previous,
			                  current: storage.elements,
			                  inserts: inserts.subtracting(updates),
			                  deletes: deletes.subtracting(updates),
			                  updates: updates)
			innerObserver.send(value: delta)
		}
	}

	public func reserveCapacity(_ n: Int) {
		storage.modify { $0.reserveCapacity(n) }
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
