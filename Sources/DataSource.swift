import Foundation
import ReactiveSwift
import Result

// FIXME: Swift 4 Associated Type Constraints
//
// open class DataSource<Delta>: NSObject
// where Delta: IndexingDelta, Delta.Snapshot.Element: IndexingDeltaSection
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
public typealias _DataSourceBase = NSObject
#else
open class _DataSourceBase {}
#endif

open class DataSource<Delta: IndexingDelta>: _DataSourceBase
where Delta.IndexPairs.Iterator.Element == (Delta.Snapshot.Index,Delta.Snapshot.Index),
      Delta.Snapshot.Index == Delta.ChangeRepresentation.Iterator.Element,
      Delta.Snapshot.IndexDistance.Stride: SignedInteger,
      Delta.Snapshot.Iterator.Element: IndexingDeltaSection,
      Delta.Snapshot.Iterator.Element.Delta: IndexingDelta,
      Delta.Snapshot.Iterator.Element.Delta.IndexPairs.Iterator.Element == (Delta.Snapshot.Iterator.Element.Delta.Snapshot.Index, Delta.Snapshot.Iterator.Element.Delta.Snapshot.Index),
      Delta.Snapshot.Iterator.Element.Delta.Snapshot.Index == Delta.Snapshot.Iterator.Element.Delta.ChangeRepresentation.Iterator.Element,
      Delta.Snapshot.Iterator.Element.Delta.Snapshot.IndexDistance.Stride: SignedInteger {
	public enum Event {
		case reloadAll
		case reloadSections(IndexSet)
		case insertSections(IndexSet)
		case deleteSections(IndexSet)
		case moveSection(source: Int, destination: Int)
		case insertRows(IndexSet, section: Int)
		case deleteRows(IndexSet, section: Int)
		case reloadRows(IndexSet, section: Int)
		case moveRow(source: Int, destination: Int, section: Int)
	}

	private var sections: ContiguousArray<Section>
	private var producer: SignalProducer<Delta, NoError>?
	private let canTraverseBidirectionally: Bool

	public var sectionCount: Int {
		return sections.count
	}

	public init(deltas producer: SignalProducer<Delta, NoError>, canInnerTraverseBidirectionally: Bool = false) {
		self.sections = []
		self.producer = producer
		self.canTraverseBidirectionally = canInnerTraverseBidirectionally
	}

	deinit {
		for section in sections {
			section.disposable.dispose()
		}
	}

	public final func rowCount(section: Int) -> Int {
		return sections[section].count
	}

	public final subscript(section: Int, row: Int) -> Delta.Snapshot.Iterator.Element.Delta.Snapshot.Iterator.Element {
		return sections[section][row]
	}

	open func update(_ action: ((Event) -> Void) -> Void) {
		fatalError("Subclasses must implement this method.")
	}

	public final func start() -> Disposable? {
		guard let producer = self.producer else {
			return nil
		}

		self.producer = nil

		// Force the `UITableView` to flush the default data source.
		self.update { handler in
			handler(.reloadAll)
		}

		return producer.startWithValues { delta in
			func insertSection(
				_ deltaProducer: SignalProducer<Delta.Snapshot.Iterator.Element.Delta, NoError>,
				at offset: Int
				) {
				let section = Section(deltaProducer, dataSource: self, initialOffset: offset, canTraverseBidirectionally: self.canTraverseBidirectionally)
				self.sections.insert(section, at: offset)
			}

			self.update { handler in
				var deleteOffsets = IndexSet()
				var moveOffsets: [(Section, Int)] = []

				if !delta.deletes.isEmpty {
					var previousIndex = delta.previous.startIndex
					var offset = 0

					for index in delta.deletes {
						offset += Int(delta.previous.distance(from: previousIndex, to: index).toIntMax())
						previousIndex = index

						deleteOffsets.insert(offset)

						let section = self.sections[offset]
						section.disposable.dispose()
					}

					handler(.deleteSections(deleteOffsets))
				}

				if !delta.moves.isEmpty {
					moveOffsets.reserveCapacity(Int(delta.moves.count.toIntMax()))

					var previousIndex1 = delta.previous.startIndex
					var previousIndex2 = delta.current.startIndex

					var offset1 = 0
					var offset2 = 0

					for (previous, current) in delta.moves {
						offset1 += Int(delta.previous.distance(from: previousIndex1, to: previous).toIntMax())
						previousIndex1 = previous

						offset2 += Int(delta.current.distance(from: previousIndex2, to: current).toIntMax())
						previousIndex2 = current

						deleteOffsets.insert(offset1)
						moveOffsets.append((self.sections[offset1], offset2))

						handler(.moveSection(source: offset1, destination: offset2))
					}
				}

				if !deleteOffsets.isEmpty {
					for index in deleteOffsets.reversed() {
						self.sections.remove(at: index)
					}
				}

				if !moveOffsets.isEmpty {
					moveOffsets.sort { $0.1 < $1.1 }

					for (section, index) in moveOffsets {
						self.sections.insert(section, at: index)
					}
				}

				if !delta.inserts.isEmpty {
					var previousIndex = delta.current.startIndex
					var offset = 0
					var inserted = IndexSet()

					for index in delta.inserts {
						offset += Int(delta.current.distance(from: previousIndex, to: index).toIntMax())
						previousIndex = index

						inserted.insert(offset)
						insertSection(delta.current[index].deltas, at: offset)
					}

					handler(.insertSections(inserted))
				}

				if !delta.updates.isEmpty {
					var previousIndex = delta.previous.startIndex
					var offset = 0
					var reloaded = IndexSet()

					for index in delta.updates {
						offset += Int(delta.previous.distance(from: previousIndex, to: index).toIntMax())
						previousIndex = index

						reloaded.insert(offset)

						let old = self.sections.remove(at: offset)
						old.disposable.dispose()

						insertSection(delta.current[index].deltas, at: offset)
					}
					
					handler(.reloadSections(reloaded))
				}
				
				for offset in self.sections.startIndex ..< self.sections.endIndex {
					self.sections[offset].sectionOffset = offset
				}
			}
		}
	}
}

extension DataSource {
	fileprivate final class Section {
		fileprivate typealias LocalDelta = Delta.Snapshot.Iterator.Element.Delta

		private var current: LocalDelta.Snapshot!
		private var position: (offset: Int, index: LocalDelta.Snapshot.Index)?
		private unowned let dataSource: DataSource

		fileprivate var disposable: Disposable!
		fileprivate var sectionOffset: Int
		private let canTraverseBidirectionally: Bool

		var count: Int {
			return Int(current.count.toIntMax())
		}

		init(_ producer: SignalProducer<LocalDelta, NoError>, dataSource: DataSource, initialOffset: Int, canTraverseBidirectionally: Bool) {
			self.current = nil
			self.dataSource = dataSource
			self.sectionOffset = initialOffset
			self.canTraverseBidirectionally = canTraverseBidirectionally
			self.disposable = producer
				.on(value: { delta in
					self.current = delta.current
					self.position = nil
				})
				.skip(first: 1)
				.startWithValues { delta in
					let currentCount = delta.current.count.toIntMax()
					let previousCount = delta.previous.count.toIntMax()

					if currentCount == 0 || previousCount == 0 || currentCount == previousCount {
						self.current = delta.current
						self.dataSource.update { handler in
							handler(.reloadSections(IndexSet(integer: self.sectionOffset)))
						}
						return
					}

					self.dataSource.update { handler in
						if !delta.deletes.isEmpty {
							handler(.deleteRows(LocalDelta.computeOffsets(for: delta.deletes, in: delta.previous),
							                    section: self.sectionOffset))
						}

						if !delta.updates.isEmpty {
							handler(.reloadRows(LocalDelta.computeOffsets(for: delta.updates, in: delta.current),
							                    section: self.sectionOffset))
						}

						if !delta.inserts.isEmpty {
							handler(.insertRows(LocalDelta.computeOffsets(for: delta.inserts, in: delta.current),
							                    section: self.sectionOffset))
						}

						if !delta.moves.isEmpty {
							let moveOffsets = LocalDelta.computeOffsetPairs(from: delta.moves, in: (delta.previous, delta.current))
							for (previous, current) in moveOffsets {
								handler(.moveRow(source: previous, destination: current, section: self.sectionOffset))
							}
						}
					}
				}
		}

		subscript(row: Int) -> LocalDelta.Snapshot.Iterator.Element {
			let index: LocalDelta.Snapshot.Index

			if let position = position, canTraverseBidirectionally || position.offset < row {
				let offset = LocalDelta.Snapshot.IndexDistance((row - position.offset).toIntMax())
				index = current.index(position.index, offsetBy: offset)
			} else {
				let offset = LocalDelta.Snapshot.IndexDistance(row.toIntMax())
				index = current.index(current.startIndex, offsetBy: offset)
			}

			position = (offset: row, index: index)

			return current[index]
		}
	}
}

extension DataSource.Event: Equatable {
	public static func ==(left: DataSource<Delta>.Event, right: DataSource<Delta>.Event) -> Bool {
		switch (left, right) {
		case (.reloadAll, .reloadAll):
			return true
		case let (.reloadSections(left), .reloadSections(right)):
			return left == right
		case let (.insertSections(left), .insertSections(right)):
			return left == right
		case let (.deleteSections(left), .deleteSections(right)):
			return left == right
		case let (.moveSection(leftSource, leftDestination), .moveSection(rightSource, rightDestination)):
			return leftSource == rightSource && leftDestination == rightDestination
		case let (.insertRows(leftRows, leftSection), .insertRows(rightRows, rightSection)):
			return leftSection == rightSection && leftRows == rightRows
		case let (.deleteRows(leftRows, leftSection), .deleteRows(rightRows, rightSection)):
			return leftSection == rightSection && leftRows == rightRows
		case let (.reloadRows(leftRows, leftSection), .reloadRows(rightRows, rightSection)):
			return leftSection == rightSection && leftRows == rightRows
		case let (.moveRow(leftSource, leftDestination, leftSection), .moveRow(rightSource, rightDestination, rightSection)):
			return leftSection == rightSection && leftSource == rightSource && leftDestination == rightDestination
		default:
			return false
		}
	}
}
