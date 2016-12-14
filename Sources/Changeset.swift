import Foundation

public enum Change<T> {
    case item(T, at: Int)
    case items([T], range: CountableRange<Int>)
}

extension Change where T: Equatable {

    public static func ==(lhs: Change<T>, rhs: Change<T>) -> Bool {
        switch (lhs, rhs) {
        case let (.item(leftItem, leftIndex), .item(rightItem, rightIndex)):
            return leftIndex == rightIndex
                && leftItem == rightItem
        case let (.items(leftItems, leftRange), .items(rightItems, rightRange)):
            return leftRange == rightRange
                && leftItems == rightItems
        default:
            return false
        }
    }

    // TODO: Keep while we haven't `SE-0143: Conditional conformances` (expected in Swift 4)
    fileprivate static func equalChanges(_ lhs: [Change<T>], _ rhs: [Change<T>]) -> Bool {
        guard lhs.count == rhs.count else { return false }

        return zip(lhs, rhs)
            .map(==)
            .reduce(true, { $0 && $1 })
    }
}

public enum Update<T> {
    case item(old: T, new: T, at: Int)
    case items(old: [T], new: [T], range: CountableRange<Int>)
}

extension Update where T: Equatable {

    public static func ==(lhs: Update<T>, rhs: Update<T>) -> Bool {
        switch (lhs, rhs) {
        case let (.item(leftOldItem, leftNewItem, leftIndex), .item(rightOldItem, rightNewItem, rightIndex)):
            return leftIndex == rightIndex
                && leftOldItem == rightOldItem
                && leftNewItem == rightNewItem
        case let (.items(leftOldItems, leftNewItems, leftRange), .items(rightOldItems, rightNewItems, rightRange)):
            return leftRange == rightRange
                && leftOldItems == rightOldItems
                && leftNewItems == rightNewItems
        default:
            return false
        }
    }

    // TODO: Keep while we haven't `SE-0143: Conditional conformances` (expected in Swift 4)
    fileprivate static func equalUpdates(_ lhs: [Update<T>], _ rhs: [Update<T>]) -> Bool {
        guard lhs.count == rhs.count else { return false }

        return zip(lhs, rhs)
            .map(==)
            .reduce(true, { $0 && $1 })
    }
}

public struct Changeset<T> {
    public let inserts: [Change<T>]
    public let removes: [Change<T>]
    public let updates: [Update<T>]
}

extension Changeset where T: Equatable {

    public static func ==(lhs: Changeset<T>, rhs: Changeset<T>) -> Bool {
        guard
            lhs.inserts.count == rhs.inserts.count,
            lhs.removes.count == rhs.removes.count,
            lhs.updates.count == rhs.updates.count
            else { return false }

        return Change.equalChanges(lhs.inserts, rhs.inserts)
            && Change.equalChanges(lhs.removes, rhs.removes)
            && Update.equalUpdates(lhs.updates, rhs.updates)
    }
}

extension Changeset {

    internal static func generate<C>(
        insert: (items: C, range: Range<Int>)?,
        remove: (items: C, range: Range<Int>)?
        ) -> Changeset<T> where C: Collection, C.Iterator.Element == T {

        precondition(insert != nil || remove != nil)

        return Changeset(
            inserts: insert.flatMap(changes) ?? [],
            removes: remove.flatMap(changes) ?? [],
            updates: []
        )
    }

    private static func changes<C>(
        elements: C,
        at range: Range<Int>
        ) -> [Change<T>] where C: Collection, C.Iterator.Element == T {

        switch elements.count {
        case 0:  return []
        case 1:  return [.item(elements.first!, at: range.lowerBound)]
        default:
            let items = Array(elements)
            let range = range.count != items.count
                ? range.lowerBound..<range.lowerBound.advanced(by: items.count)
                : CountableRange(range)

            assert(items.count == range.count)

            return [.items(items, range: range)]
        }
    }
}
