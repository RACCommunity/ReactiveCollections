import Foundation
import ReactiveSwift
import Result

public final class ReactiveArray<Element> {

    fileprivate var elements: ContiguousArray<Element>

    fileprivate let innerObserver: Observer<Changeset<Element>, NoError>

    public let signal: Signal<Changeset<Element>, NoError>

    public var producer: SignalProducer<Changeset<Element>, NoError> {
        return SignalProducer.attempt { [weak self] () -> Result<Changeset<Element>, NSError> in
            guard let `self` = self else { return .failure(NSError()) }

            return .success(
                Changeset.generate(
                    insert: (items: self[self.indices], range: Range(self.indices)),
                    remove: nil
                )
            )

            }
            .flatMapError { _ in .empty }
            .concat(SignalProducer(signal: signal))
    }

    public init(_ elements: [Element]) {
        self.elements = ContiguousArray(elements)

        (signal, innerObserver) = Signal<Changeset<Element>, NoError>.pipe()
    }

    public convenience init() {
        self.init([])
    }

    deinit {
        innerObserver.sendCompleted()
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
            replaceSubrange(position..<position, with: CollectionOfOne(newValue))
        }
    }

    public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
        get {
            return elements[bounds]
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
        let result = self[position]
        removeSubrange(position..<index(after: position))
        return result
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        if keepCapacity {
            removeSubrange(indices)
        } else {
            let changeset = Changeset.generate(
                insert: nil,
                remove: (items: self[indices], range: Range(indices))
            )

            elements.removeAll()

            innerObserver.send(value: changeset)
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

        let changeset = Changeset.generate(
            insert: (items: ArraySlice(newElements), range: subrange),
            remove: (items: elements[subrange], range: subrange)
        )

        elements.replaceSubrange(subrange, with: newElements)

        innerObserver.send(value: changeset)
    }

    public func reserveCapacity(_ n: Int) {
        elements.reserveCapacity(n)
    }
}
