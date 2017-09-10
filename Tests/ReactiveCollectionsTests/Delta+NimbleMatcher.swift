import Nimble
import ReactiveCollections

internal func ==<T: Equatable, C: Collection>(
	_ array: Expectation<ReactiveArray<T>>,
	_ collection: C
) where C.Iterator.Element == T {
	array.to(Predicate.define { expression in
		let value = try expression.evaluate()!

		if value.elementsEqual(collection, by: ==) {
			return PredicateResult(status: .matches, message: .expectedTo("succeeds"))
		}

		return PredicateResult(status: .doesNotMatch,
		                       message: .expectedActualValueTo("match \(collection)"))
	})
}

internal func ==<C: Collection>(
	left: Expectation<Snapshot<C>>,
	right: Snapshot<C>
) where C.Iterator.Element: Equatable {
	return left.to(Predicate.define { expression in
		let value = try expression.evaluate()!

		if value == right {
			return PredicateResult(status: .matches, message: .expectedTo("succeeds"))
		}

		return PredicateResult(status: .doesNotMatch,
		                       message: .expectedActualValueTo("match \(right)"))
	})
}

internal func ==<C: Collection>(
	left: Expectation<[Snapshot<C>]>,
	right: [Snapshot<C>]
) where C.Iterator.Element: Equatable {
	return left.to(Predicate.define { expression in
		let value = try expression.evaluate()!

		if value.elementsEqual(right, by: ==) {
			return PredicateResult(status: .matches, message: .expectedTo("succeeds"))
		}

		return PredicateResult(status: .doesNotMatch,
		                       message: .expectedActualValueTo("match \(right)"))
	})
}

internal func ==<C1: Collection, C2: Collection>(
	_ expectation: Expectation<C1>,
	_ expected: C2
) where C1.Iterator.Element: Equatable, C1.Iterator.Element == C2.Iterator.Element {
	expectation.to(equal(expected, by: ==))
}

internal func equal<C1: Collection, C2: Collection>(
	_ expected: C2,
	original: C2? = nil,
	changeset: Changeset? = nil,
	by areEqual: @escaping (C2.Iterator.Element, C2.Iterator.Element) -> Bool
) -> Predicate<C1> where C1.Iterator.Element == C2.Iterator.Element {
	return Predicate.define { expression in
		let value = try expression.evaluate()!

		if value.elementsEqual(expected, by: areEqual) {
			return PredicateResult(status: .matches, message: .expectedTo("succeeds"))
		}

		let message = "match \(expected)"
			+ (original.map { ", original \($0)" } ?? "")
			+ (changeset.map { ", changeset \($0)" } ?? "")

		return PredicateResult(status: .doesNotMatch,
		                       message: .expectedActualValueTo(message))
	}
}
