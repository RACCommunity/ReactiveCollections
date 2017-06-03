import Nimble
import ReactiveCollections

internal func ==<T: Equatable, C: Collection>(_ array: Expectation<ReactiveArray<T>>, _ collection: C) where C.Iterator.Element == T {
	array.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value.elementsEqual(collection, by: ==) {
			return true
		}

		failureMessage.actualValue = String(reflecting: value)
		failureMessage.expected = String(reflecting: collection)
		return false
	})
}

internal func ==<ChangeRepresentation>(
	left: Expectation<Delta<ChangeRepresentation>>,
	right: Delta<ChangeRepresentation>
) where ChangeRepresentation: Equatable {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value == right {
			return true
		}

		failureMessage.expected = "expected \(String(reflecting: right))"
		failureMessage.to = ""
		failureMessage.actualValue = String(reflecting: value)
		return false
	})
}

internal func ==<Delta: IndexingDelta>(
	left: Expectation<Delta>,
	right: Delta
) where Delta.Snapshot.Iterator.Element: Equatable, Delta.ChangeRepresentation: Equatable, Delta.IndexPairs.Iterator.Element == (Delta.Snapshot.Index, Delta.Snapshot.Index) {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value == right {
			return true
		}

		failureMessage.expected = "expected \(String(reflecting: right))"
		failureMessage.to = ""
		failureMessage.actualValue = String(reflecting: value)
		return false
	})
}

internal func ==<Delta: IndexingDelta>(
	left: Expectation<[Delta]>,
	right: [Delta]
) where Delta.Snapshot.Iterator.Element: Equatable, Delta.ChangeRepresentation: Equatable, Delta.IndexPairs.Iterator.Element == (Delta.Snapshot.Index, Delta.Snapshot.Index) {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value.elementsEqual(right, by: ==) {
			return true
		}

		failureMessage.expected = "expected \(String(reflecting: right))"
		failureMessage.to = ""
		failureMessage.actualValue = String(reflecting: value)
		return false
	})
}
