import Nimble
import Quick
import ReactiveSwift
import Result
import Foundation
#if os(Linux)
import Glibc
#else
import Darwin.C
#endif
@testable import ReactiveCollections

private class ObjectValue {}

private struct Pair<Key: Hashable, Value: Equatable>: Hashable {
	var key: Key
	var value: Value

	var hashValue: Int {
		return key.hashValue
	}

	init(key: Key, value: Value) {
		self.key = key
		self.value = value
	}

	static func ==(left: Pair<Key, Value>, right: Pair<Key, Value>) -> Bool {
		return left.key == right.key && left.value == right.value
	}
}

class CollectionDiffingSpec: QuickSpec {
	override func spec() {
		describe("operations") {
			func test<C: Collection>(from original: C, to final: C, setup: (Signal<C, NoError>) -> Signal<Snapshot<C>, NoError>, expecting: @escaping (Changeset) -> Void) {
				let (snapshots, snapshotObserver) = Signal<C, NoError>.pipe()
				let deltas = setup(snapshots)

				deltas.skip(first: 1).observeValues { snapshot in
					expecting(snapshot.changeset)
				}

				snapshotObserver.send(value: original)
				snapshotObserver.send(value: final)
			}

			describe("insertions") {
				it("should reflect an insertion at the beginning") {
					test(from: [0, 1, 2, 3],
					     to: [10, 0, 1, 2, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [0])
					}
				}

				it("should reflect contiguous insertions at the beginning") {
					test(from: [0, 1, 2, 3],
					     to: [10, 11, 12, 0, 1, 2, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [0, 1, 2])
					}
				}

				it("should reflect an insertion in the middle") {
					test(from: [0, 1, 2, 3],
					     to: [0, 1, 10, 2, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [2])
					}
				}

				it("should reflect contiguous insertions in the middle") {
					test(from: [0, 1, 2, 3],
					     to: [0, 1, 10, 11, 12, 2, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [2, 3, 4])
					}
				}

				it("should reflect scattered insertions in the middle") {
					test(from: [0, 1, 2, 3],
					     to: [0, 10, 1, 11, 2, 12, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [1, 3, 5])
					}
				}

				it("should reflect an insertion at the end") {
					test(from: [0, 1, 2, 3],
					     to: [0, 1, 2, 3, 10],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [4])
					}
				}

				it("should reflect contiguous insertions at the end") {
					test(from: [0, 1, 2, 3],
					     to: [0, 1, 2, 3, 10, 11, 12],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(inserts: [4, 5, 6])
					}
				}
			}

			describe("deletions") {
				it("should reflect a removal at the beginning") {
					test(from: [0, 1, 2, 3],
					     to: [1, 2, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [0])
					}
				}

				it("should reflect contiguous removals at the beginning") {
					test(from: [0, 1, 2, 3],
					     to: [3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [0, 1, 2])
					}
				}

				it("should reflect a removal in the middle") {
					test(from: [0, 1, 2, 3],
					     to: [0, 1, 3],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [2])
					}
				}

				it("should reflect contiguous removals in the middle") {
					test(from: [0, 1, 2, 3, 4],
					     to: [0, 4],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [1, 2, 3])
					}
				}

				it("should reflect scattered contiguous removals in the middle") {
					test(from: [0, 1, 2, 3, 4, 5, 6, 7, 8],
					     to: [0, 3, 7],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [1, 2, 4, 5, 6, 8])
					}
				}

				it("should reflect a removal at the end") {
					test(from: [0, 1, 2, 3],
					     to: [0, 1, 2],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [3])
					}
				}

				it("should reflect contiguous removals at the end") {
					test(from: [0, 1, 2, 3],
					     to: [0],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [1, 2, 3])
					}
				}
			}

			describe("mutations") {
				// Mutations can happen only if the identifying strategy differs from the
				// comparing strategy.

				it("should reflect a mutation at the beginning") {
					test(from: [Pair(key: "k1", value: "v1_old"),
					            Pair(key: "k2", value: "v2"),
					            Pair(key: "k3", value: "v3")],
					     to: [Pair(key: "k1", value: "v1_new"),
					          Pair(key: "k2", value: "v2"),
					          Pair(key: "k3", value: "v3")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [0])
					}
				}

				it("should reflect contiguous mutations at the beginning") {
					test(from: [Pair(key: "k1", value: "v1_old"),
					            Pair(key: "k2", value: "v2_old"),
					            Pair(key: "k3", value: "v3_old"),
					            Pair(key: "k4", value: "v4")],
					     to: [Pair(key: "k1", value: "v1_new"),
					          Pair(key: "k2", value: "v2_new"),
					          Pair(key: "k3", value: "v3_new"),
					          Pair(key: "k4", value: "v4")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [0, 1, 2])
					}
				}

				it("should reflect a mutation in the middle") {
					test(from: [Pair(key: "k1", value: "v1"),
					            Pair(key: "k2", value: "v2"),
					            Pair(key: "k3", value: "v3_old"),
					            Pair(key: "k4", value: "v4")],
					     to: [Pair(key: "k1", value: "v1"),
					          Pair(key: "k2", value: "v2"),
					          Pair(key: "k3", value: "v3_new"),
					          Pair(key: "k4", value: "v4")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [2])
					}
				}

				it("should reflect contiguous mutations in the middle") {
					test(from: [Pair(key: "k1", value: "v1"),
					            Pair(key: "k2", value: "v2_old"),
					            Pair(key: "k3", value: "v3_old"),
					            Pair(key: "k4", value: "v4_old"),
					            Pair(key: "k5", value: "v5_old"),
					            Pair(key: "k6", value: "v6")],
					     to: [Pair(key: "k1", value: "v1"),
					          Pair(key: "k2", value: "v2_new"),
					          Pair(key: "k3", value: "v3_new"),
					          Pair(key: "k4", value: "v4_new"),
					          Pair(key: "k5", value: "v5_new"),
					          Pair(key: "k6", value: "v6")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [1, 2, 3, 4])
					}
				}

				it("should reflect scattered mutations in the middle") {
					test(from: [Pair(key: "k1", value: "v1"),
					            Pair(key: "k2", value: "v2_old"),
					            Pair(key: "k3", value: "v3"),
					            Pair(key: "k4", value: "v4_old"),
					            Pair(key: "k5", value: "v5"),
					            Pair(key: "k6", value: "v6"),
					            Pair(key: "k7", value: "v7_old"),
					            Pair(key: "k8", value: "v8")],
					     to: [Pair(key: "k1", value: "v1"),
					          Pair(key: "k2", value: "v2_new"),
					          Pair(key: "k3", value: "v3"),
					          Pair(key: "k4", value: "v4_new"),
					          Pair(key: "k5", value: "v5"),
					          Pair(key: "k6", value: "v6"),
					          Pair(key: "k7", value: "v7_new"),
					          Pair(key: "k8", value: "v8")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [1, 3, 6])
					}
				}

				it("should reflect a mutation at the end") {
					test(from: [Pair(key: "k1", value: "v1"),
					            Pair(key: "k2", value: "v2"),
					            Pair(key: "k3", value: "v3_old")],
					     to: [Pair(key: "k1", value: "v1"),
					          Pair(key: "k2", value: "v2"),
					          Pair(key: "k3", value: "v3_new")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [2])
					}
				}

				it("should reflect contiguous mutations at the end") {
					test(from: [Pair(key: "k1", value: "v1"),
					            Pair(key: "k2", value: "v2_old"),
					            Pair(key: "k3", value: "v3_old"),
					            Pair(key: "k4", value: "v4_old")],
					     to: [Pair(key: "k1", value: "v1"),
					          Pair(key: "k2", value: "v2_new"),
					          Pair(key: "k3", value: "v3_new"),
					          Pair(key: "k4", value: "v4_new")],
					     setup: { $0.diff(identifier: { $0.key }, areEqual: ==) }) {
						expect($0) == Changeset(mutations: [1, 2, 3])
					}
				}
			}

			// Move tests are disabled for now, until the algorithm has been updated to
			// eliminate redundant moves.
/*
			describe("moves") {
				it("should reflect a forward move") {
					test(from: [0, 1, 2, 3, 4],
					     to: [1, 2, 3, 0, 4],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(moves: [Changeset.Move(source: 0, destination: 3, isMutated: false)])
					}
				}

				it("should reflect a backward move") {
					test(from: [0, 1, 2, 3, 4],
					     to: [3, 0, 1, 2, 4],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(moves: [Changeset.Move(source: 3, destination: 0, isMutated: false)])
					}
				}
			}

			describe("removals and moves") {
				it("should reflect a forward move and a removal") {
					test(from: [0, 1, 2, 3, 4],
					     to: [2, 3, 0, 4],
					     setup: { $0.diff() }) {
						expect($0) == Changeset(removals: [1],
						                        moves: [Changeset.Move(source: 0, destination: 2, isMutated: false)])
					}
				}
			}
*/
		}

		describe("reproducibility") {
			func reproducibilityTest<C: RangeReplaceableCollection>(from original: C, to final: C, areEqual: @escaping (C.Iterator.Element, C.Iterator.Element) -> Bool, setup: (Signal<C, NoError>) -> Signal<Snapshot<C>, NoError>) {
				let (snapshots, snapshotObserver) = Signal<C, NoError>.pipe()
				let deltas = setup(snapshots)

				var snapshot: Snapshot<C>?

				deltas.observeValues {
					snapshot = $0
				}
				expect(snapshot).to(beNil())

				snapshotObserver.send(value: original)
				expect(snapshot).toNot(beNil())
				expect(snapshot?.previous).to(beNil())

				snapshotObserver.send(value: final)
				expect(snapshot).toNot(beNil())
				expect(snapshot?.previous).toNot(beNil())

				if let snapshot = snapshot, let previous = snapshot.previous {
					var values = previous
					expect(values.elementsEqual(original, by: areEqual)) == true

					snapshot.changeset.removals
						.union(IndexSet(snapshot.changeset.moves.lazy.map { $0.source }))
						.reversed()
						.forEach { offset in
							let index = values.index(values.startIndex, offsetBy: C.IndexDistance(offset))
							values.remove(at: index)
						}

					snapshot.changeset.mutations.forEach { offset in
						let index = values.index(values.startIndex, offsetBy: C.IndexDistance(offset))
						let index2 = snapshot.current.index(snapshot.current.startIndex, offsetBy: C.IndexDistance(offset))
						values.replaceSubrange(index ..< values.index(after: index),
						                       with: CollectionOfOne(snapshot.current[index2]))
					}

					snapshot.changeset.inserts
						.union(IndexSet(snapshot.changeset.moves.lazy.map { $0.destination }))
						.forEach { offset in
							let index = values.index(values.startIndex, offsetBy: C.IndexDistance(offset))
							let index2 = snapshot.current.index(snapshot.current.startIndex, offsetBy: C.IndexDistance(offset))
							values.insert(snapshot.current[index2], at: index)
						}

					expect(values).to(equal(final, by: areEqual))
				}
			}

			describe("Hashable elements") {
				it("should produce a snapshot that can be reproduced from the previous snapshot by applying the changeset") {
					let numbers = Array(0 ..< 64).shuffled()
					let newNumbers = Array(numbers.dropLast(8) + (128 ..< 168)).shuffled()

					reproducibilityTest(from: numbers,
					                    to: newNumbers,
					                    areEqual: ==,
					                    setup: { $0.diff() })
				}

				it("should produce a snapshot that can be reproduced from the previous snapshot by applying the changeset, even if the collection is bidirectional") {
					let oldCharacters = "abcdefghijkl12345~!@%^&*()_-+=".characters.shuffled()
					var newCharacters = oldCharacters.dropLast(8)
					newCharacters.append(contentsOf: "mnopqrstuvwxyz67890#".characters)
					newCharacters = newCharacters.shuffled()

					reproducibilityTest(from: oldCharacters,
					                    to: newCharacters,
					                    areEqual: ==,
					                    setup: { $0.diff() })
				}
			}

			describe("AnyObject elements") {
				it("should produce a snapshot that can be reproduced from the previous snapshot by applying the changeset") {
					let objects = Array(0 ..< 64).map { _ in ObjectValue() }.shuffled()
					let newObjects = (Array(objects.dropLast(8)) + (0 ..< 32).map { _ in ObjectValue() }).shuffled()

					reproducibilityTest(from: objects,
					                    to: newObjects,
					                    areEqual: ===,
					                    setup: { $0.diff() })
				}
			}
		}
	}
}

private extension RangeReplaceableCollection where Index == Indices.Iterator.Element {
	func shuffled() -> Self {
		var elements = self

		for i in 0 ..< Int(elements.count) {
			let distance = randomInteger() % Int(elements.count)
			let random = elements.index(elements.startIndex, offsetBy: IndexDistance(distance))
			let index = elements.index(elements.startIndex, offsetBy: IndexDistance(i))
			guard random != index else { continue }

			let temp = elements[index]
			elements.replaceSubrange(index ..< elements.index(after: index), with: CollectionOfOne(elements[random]))
			elements.replaceSubrange(random ..< elements.index(after: random), with: CollectionOfOne(temp))
		}

		return elements
	}
}

#if !swift(>=3.2)
	extension SignedInteger {
		fileprivate init<I: SignedInteger>(_ integer: I) {
			self.init(integer.toIntMax())
		}
	}
#endif

#if os(Linux)
	private func randomInteger() -> Int {
		srandom(UInt32(time(nil)))
		return Int(random() >> 1)
	}
#else
	private func randomInteger() -> Int {
		return Int(arc4random() >> 1)
	}
#endif
