import Nimble
import ReactiveCollections

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

internal func ==<C1: Collection, C2: Collection>(_ expectation: Expectation<C1>, _ expected: C2) where C1.Iterator.Element: Equatable, C1.Iterator.Element == C2.Iterator.Element {
	expectation.to(equal(expected, by: ==))
}

internal func equal<C1: Collection, C2: Collection>(
	_ expected: C2,
	by areEqual: @escaping (C2.Iterator.Element, C2.Iterator.Element) -> Bool
) -> NonNilMatcherFunc<C1> where C1.Iterator.Element == C2.Iterator.Element {
	return NonNilMatcherFunc { expression, failureMessage in
		let value = try expression.evaluate()!

		if value.elementsEqual(expected, by: areEqual) {
			return true
		}

		failureMessage.actualValue = String(reflecting: value)
		failureMessage.expected = String(reflecting: expected)
		return false
	}
}
