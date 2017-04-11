import Nimble
import ReactiveCollections

internal func ==<Snapshot, ChangeRepresentation>(
	left: Expectation<[Delta<Snapshot, ChangeRepresentation>]>,
	right: [Delta<Snapshot, ChangeRepresentation>]
) where Snapshot.Iterator.Element: Equatable, ChangeRepresentation: Equatable {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		return try expression.evaluate()!.elementsEqual(right) { $0 == $1 }
	})
}
