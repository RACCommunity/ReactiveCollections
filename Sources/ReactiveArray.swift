import Foundation
import ReactiveSwift
import enum Result.NoError

public enum Change<T> {
    case insert(element: T, at: Int)
    case remove(element: T, at: Int)
}

public final class ReactiveArray<Element> {

    fileprivate var elements: ContiguousArray<Element>

    fileprivate let innerObserver: Observer<[Change<Element>], NoError>

    public let signal: Signal<[Change<Element>], NoError>

    public var capacity: Int {
        return elements.capacity
    }

    public init(_ elements: [Element]) {
        self.elements = ContiguousArray(elements)

        (signal, innerObserver) = Signal<[Change<Element>], NoError>.pipe()
    }

    deinit {
        innerObserver.sendCompleted()
    }

}

extension ReactiveArray: ExpressibleByArrayLiteral {

    public convenience init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension ReactiveArray: MutableCollection {

    public typealias SubSequence = ArraySlice<Element>
    public typealias Index = Int

    public var startIndex: Index {
        return elements.startIndex
    }

    public var endIndex: Index {
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

    public subscript(bounds: Range<Int>) -> SubSequence {
        get {
            return elements[bounds]
        }
        set {
            replaceSubrange(bounds, with: newValue)
        }
    }
}

extension ReactiveArray: RandomAccessCollection {

    public typealias Indices = CountableRange<Int>
}

extension ReactiveArray: RangeReplaceableCollection {

    public convenience init() {
        self.init([])
    }

    public convenience init(repeating repeatedValue: Element, count: Int) {
        self.init(Array(repeating: repeatedValue, count: count))
    }

    public func reserveCapacity(_ n: Int) {
        elements.reserveCapacity(n)
    }

    // TODO: Implement a custom append(contentsOf:) to behave like an 
    // insert(contentsOf:at:), trigger a single update instead of N with N being
    // the number of elements appended

    /// NOTE: We can't use the default implementation when we don't want to keep
    /// array's capacity since Swift Standard Library initializes a whole new
    /// instance as an optimization
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        if keepCapacity {
            replaceSubrange(startIndex..<endIndex, with: EmptyCollection())
        } else {

            let changes = elements[indices]
                .enumerated()
                .map(flip(Change.remove))

            elements.removeAll()

            innerObserver.send(value: changes)
        }
    }

    public func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Element {
        var changes: [Change<Element>] = []

        changes += elements[subrange]
            .enumerated()
            .map { ($0.advanced(by: subrange.lowerBound), $1) }
            .map(flip(Change.remove))

        changes += newElements
            .enumerated()
            .map { ($0.advanced(by: subrange.lowerBound), $1) }
            .map(flip(Change.insert))

        elements.replaceSubrange(subrange, with: newElements)

        innerObserver.send(value: changes)
    }
}

// MARK: - Helpers

private func flip<T, U, V>(_ function: @escaping (T, U) -> V) -> (U, T) -> V {
    return { function($1, $0) }
}
