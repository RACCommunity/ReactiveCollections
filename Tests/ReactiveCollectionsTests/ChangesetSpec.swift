import Nimble
import Quick
import ReactiveCollections
import Foundation

class ChangesetSpec: QuickSpec {
	override func spec() {
		describe("insertion reproducibility") {
			it("should reproduce the insertion at the beginning") {
				_ = reproducibilityTest(applying: Changeset(inserts: [0]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["e", "a", "b", "c", "d"])
			}

			it("should reproduce the insertion at the end") {
				_ = reproducibilityTest(applying: Changeset(inserts: [4]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "c", "d", "e"])
			}

			it("should reproduce the insertion in the middle") {
				_ = reproducibilityTest(applying: Changeset(inserts: [2]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "e", "c", "d"])
			}

			it("should reproduce the contiguous insertions at the beginning") {
				_ = reproducibilityTest(applying: Changeset(inserts: [0, 1, 2]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["e", "f", "g", "a", "b", "c", "d"])
			}

			it("should reproduce the contiguous insertions at the end") {
				_ = reproducibilityTest(applying: Changeset(inserts: [4, 5, 6]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "c", "d", "e", "f", "g"])
			}

			it("should reproduce the contiguous insertions in the middle") {
				_ = reproducibilityTest(applying: Changeset(inserts: [2, 3, 4]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "e", "f", "g", "c", "d"])
			}

			it("should reproduce the scattered insertions in the middle") {
				_ = reproducibilityTest(applying: Changeset(inserts: [1, 3, 4, 7]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "e", "b", "f", "g", "c", "d", "h"])
			}
		}

		describe("removal reproducibility") {
			it("should reproduce the removal at the beginning") {
				_ = reproducibilityTest(applying: Changeset(removals: [0]),
				                        to: ["e", "a", "b", "c", "d"],
				                        expecting: ["a", "b", "c", "d"])
			}

			it("should reproduce the removal at the end") {
				_ = reproducibilityTest(applying: Changeset(removals: [4]),
				                        to: ["a", "b", "c", "d", "e"],
				                        expecting: ["a", "b", "c", "d"])
			}

			it("should reproduce the removal in the middle") {
				_ = reproducibilityTest(applying: Changeset(removals: [2]),
				                        to: ["a", "b", "e", "c", "d"],
				                        expecting: ["a", "b", "c", "d"])
			}

			it("should reproduce the contiguous removals at the beginning") {
				_ = reproducibilityTest(applying: Changeset(removals: [0, 1, 2]),
				                        to: ["e", "f", "g", "a", "b", "c", "d"],
				                        expecting: ["a", "b", "c", "d"])
			}

			it("should reproduce the contiguous removals at the end") {
				_ = reproducibilityTest(applying: Changeset(removals: [4, 5, 6]),
				                        to: ["a", "b", "c", "d", "e", "f", "g"],
				                        expecting: ["a", "b", "c", "d"])
			}

			it("should reproduce the contiguous removals in the middle") {
				_ = reproducibilityTest(applying: Changeset(removals: [2, 3, 4]),
				                        to: ["a", "b", "e", "f", "g", "c", "d"],
				                        expecting: ["a", "b", "c", "d"])
			}

			it("should reproduce the scattered removals in the middle") {
				_ = reproducibilityTest(applying: Changeset(removals: [1, 3, 4, 7]),
				                        to: ["a", "e", "b", "f", "g", "c", "d", "h"],
				                        expecting: ["a", "b", "c", "d"])
			}
		}

		describe("mutation reproducibility") {
			it("should reproduce the mutation at the beginning") {
				_ = reproducibilityTest(applying: Changeset(mutations: [0]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["Z", "b", "c", "d"])
			}

			it("should reproduce the mutation at the end") {
				_ = reproducibilityTest(applying: Changeset(mutations: [3]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "c", "Z"])
			}

			it("should reproduce the mutation in the middle") {
				_ = reproducibilityTest(applying: Changeset(mutations: [1]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "Z", "c", "d"])
			}

			it("should reproduce the contiguous mutations at the beginning") {
				_ = reproducibilityTest(applying: Changeset(mutations: [0, 1, 2]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["X", "Y", "Z", "d"])
			}

			it("should reproduce the contiguous mutations at the end") {
				_ = reproducibilityTest(applying: Changeset(mutations: [1, 2, 3]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "X", "Y", "Z"])
			}

			it("should reproduce the contiguous mutations in the middle") {
				_ = reproducibilityTest(applying: Changeset(mutations: [2, 3, 4]),
				                        to: ["a", "b", "e", "f", "g", "c", "d"],
				                        expecting: ["a", "b", "X", "Y", "Z", "c", "d"])
			}

			it("should reproduce the scattered mutations in the middle") {
				_ = reproducibilityTest(applying: Changeset(mutations: [1, 3, 4, 7]),
				                        to: ["a", "e", "b", "f", "g", "c", "d", "h"],
				                        expecting: ["a", "W", "b", "Z", "Y", "c", "d", "Z"])
			}
		}

		describe("move reproducibility") {
			it("should reproduce the forward move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 1, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["b", "a", "c", "d"])
			}

			it("should reproduce the forward move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 3, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["b", "c", "d", "a"])
			}

			it("should reproduce the backward move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 3, destination: 2, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "d", "c"])
			}

			it("should reproduce the backward move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 3, destination: 0, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["d", "a", "b", "c"])
			}

			it("should reproduce the forward mutating move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 1, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["b", "Z", "c", "d"])
			}

			it("should reproduce the forward mutating move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 3, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["b", "c", "d", "Z"])
			}

			it("should reproduce the backward mutating move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 3, destination: 2, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["a", "b", "Z", "c"])
			}

			it("should reproduce the backward mutating move") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 3, destination: 0, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["Z", "a", "b", "c"])
			}

			it("should reproduce the overlapping moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 3, isMutated: false),
				                                                    .init(source: 3, destination: 0, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["d", "b", "c", "a"])
			}

			it("should reproduce the overlapping forward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 2, isMutated: false),
				                                                    .init(source: 1, destination: 3, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["c", "d", "a", "b"])
			}

			it("should reproduce the overlapping forward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 3, isMutated: false),
				                                                    .init(source: 1, destination: 2, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["c", "d", "b", "a"])
			}

			it("should reproduce the overlapping backward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 3, destination: 0, isMutated: false),
				                                                    .init(source: 2, destination: 1, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["d", "c", "a", "b"])
			}


			it("should reproduce the overlapping backward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 2, destination: 0, isMutated: false),
				                                                    .init(source: 3, destination: 1, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["c", "d", "a", "b"])
			}

			it("should reproduce the overlapping mutating moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 3, isMutated: false),
				                                                    .init(source: 3, destination: 0, isMutated: false)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["Y", "b", "c", "Z"])
			}


			it("should reproduce the overlapping mutating forward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 2, isMutated: true),
				                                                    .init(source: 1, destination: 3, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["c", "d", "Y", "Z"])
			}

			it("should reproduce the overlapping mutating forward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 0, destination: 3, isMutated: true),
				                                                    .init(source: 1, destination: 2, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["c", "d", "Z", "Y"])
			}

			it("should reproduce the overlapping mutating backward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 3, destination: 0, isMutated: true),
				                                                    .init(source: 2, destination: 1, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["Z", "Y", "a", "b"])
			}


			it("should reproduce the overlapping mutating backward moves") {
				_ = reproducibilityTest(applying: Changeset(moves: [.init(source: 2, destination: 0, isMutated: true),
				                                                    .init(source: 3, destination: 1, isMutated: true)]),
				                        to: ["a", "b", "c", "d"],
				                        expecting: ["Y", "Z", "a", "b"])
			}
		}

		describe("mixed reproducibility") {
			it("should reproduce all the operations") {
				let values = reproducibilityTest(applying: Changeset(inserts: [0, 4],
				                                                     removals: [0],
				                                                     mutations: [1],
				                                                     moves: [.init(source: 2, destination: 6, isMutated: true),
				                                                             .init(source: 3, destination: 8, isMutated: false),
				                                                             .init(source: 5, destination: 2, isMutated: false)]),
				                                 to:        "abcdefgh".characters,
				                                 expecting: "YBfeZgChd".characters)

				expect(String(values)) == "YBfeZgChd"
			}
		}
	}
}

@discardableResult
private func reproducibilityTest<C: RangeReplaceableCollection>(
	applying changeset: Changeset,
	to previous: C,
	expecting current: C,
	file: FileString = #file,
	line: UInt = #line
) -> C where C.Iterator.Element: Equatable {
	return reproducibilityTest(applying: changeset, to: previous, expecting: current, areEqual: ==, file: file, line: line)
}

@discardableResult
private func reproducibilityTest<C: RangeReplaceableCollection>(
	applying changeset: Changeset,
	to previous: C,
	expecting current: C,
	areEqual: (@escaping (C.Iterator.Element, C.Iterator.Element) -> Bool),
	file: FileString = #file,
	line: UInt = #line
) -> C {
	var values = previous
	expect(values).to(equal(previous, by: areEqual))

	// Move offset pairs are only a hint for animation and optimization. They are
	// semantically equivalent to a removal offset paired with an insertion offset.

	// (1) Copy position invariant mutations.
	for range in changeset.mutations.rangeView {
		let lowerBound = values.index(values.startIndex, offsetBy: C.IndexDistance(range.lowerBound))
		let upperBound = values.index(lowerBound, offsetBy: C.IndexDistance(range.count))
		let copyLowerBound = current.index(current.startIndex, offsetBy: C.IndexDistance(range.lowerBound))
		let copyUpperBound = current.index(copyLowerBound, offsetBy: C.IndexDistance(range.count))
		values.replaceSubrange(lowerBound ..< upperBound,
							   with: current[copyLowerBound ..< copyUpperBound])
	}

	// (2) Perform removals (including move sources).
	let removals = changeset.removals.union(IndexSet(changeset.moves.lazy.map { $0.source }))
	for range in removals.rangeView.reversed() {
		let lowerBound = values.index(values.startIndex, offsetBy: C.IndexDistance(range.lowerBound))
		let upperBound = values.index(lowerBound, offsetBy: C.IndexDistance(range.count))
		values.removeSubrange(lowerBound ..< upperBound)
	}

	// (3) Perform insertions (including move destinations).
	let inserts = changeset.inserts.union(IndexSet(changeset.moves.lazy.map { $0.destination }))
	for range in inserts.rangeView {
		let lowerBound = values.index(values.startIndex, offsetBy: C.IndexDistance(range.lowerBound))
		let copyLowerBound = current.index(current.startIndex, offsetBy: C.IndexDistance(range.lowerBound))
		let copyUpperBound = current.index(copyLowerBound, offsetBy: C.IndexDistance(range.count))
		values.insert(contentsOf: current[copyLowerBound ..< copyUpperBound], at: lowerBound)
	}

	expect(values, file: file, line: line).to(equal(current, by: areEqual))
	return values
}

#if !swift(>=3.2)
	extension SignedInteger {
		fileprivate init<I: SignedInteger>(_ integer: I) {
			self.init(integer.toIntMax())
		}
	}
#endif
