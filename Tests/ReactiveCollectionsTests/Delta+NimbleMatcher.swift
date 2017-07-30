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

internal func ==<Elements: Collection>(
	left: Expectation<Snapshot<Elements>>,
	right: Snapshot<Elements>
) where Elements.Iterator.Element: Equatable {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value == right {
			return true
		}

		failureMessage.expected = "expected \(right)"
		failureMessage.to = ""
		failureMessage.actualValue = String(describing: value)
		return false
	})
}

internal func ==<Elements: Collection>(
	left: Expectation<[Snapshot<Elements>]>,
	right: [Snapshot<Elements>]
) where Elements.Iterator.Element: Equatable {
	return left.to(NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!
		if value.elementsEqual(right, by: ==) {
			return true
		}

		failureMessage.expected = "expected \(right)"
		failureMessage.to = ""
		failureMessage.actualValue = String(describing: value)
		return false
	})
}

internal func == <Elements: Collection>(left: Snapshot<Elements>, right: Snapshot<Elements>) -> Bool where Elements.Iterator.Element: Equatable {
	var previousEqual = false

	if let lhs = left.previous, let rhs = right.previous, lhs.elementsEqual(rhs) {
		previousEqual = true
	}

	if !previousEqual {
		previousEqual = left.previous == nil && right.previous == nil
	}

	return previousEqual
		&& left.changeset == right.changeset
		&& left.current.elementsEqual(right.current)
}
