import Nimble
import ReactiveCollections

internal func ==<T: Equatable, C: Collection>(_ array: Expectation<ReactiveArray<T>>, _ collection: C) where C.Iterator.Element == T {
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
