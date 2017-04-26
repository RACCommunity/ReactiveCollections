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

internal func ==<Snapshot, ChangeRepresentation>(
	left: Expectation<Delta<Snapshot, ChangeRepresentation>>,
	right: Delta<Snapshot, ChangeRepresentation>
) where Snapshot.Iterator.Element: Equatable, ChangeRepresentation: Equatable {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value == right {
			return true
		}

		failureMessage.expected = "expected \(right.debugDescription)"
		failureMessage.to = ""
		failureMessage.actualValue = value.debugDescription
		return false
	})
}

internal func ==<Snapshot, ChangeRepresentation>(
	left: Expectation<[Delta<Snapshot, ChangeRepresentation>]>,
	right: [Delta<Snapshot, ChangeRepresentation>]
) where Snapshot.Iterator.Element: Equatable, ChangeRepresentation: Equatable {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value.elementsEqual(right, by: ==) {
			return true
		}

		failureMessage.expected = "expected \(right.debugDescription)"
		failureMessage.to = ""
		failureMessage.actualValue = value.debugDescription
		return false
	})
}
