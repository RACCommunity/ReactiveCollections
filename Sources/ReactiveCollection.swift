import ReactiveSwift
import enum Result.NoError

public protocol ReactiveCollection: class {
	/// A type that snapshots the content of the collection at an instance of
	/// time.
	associatedtype Snapshot: Collection

	// FIXME: (Swift 4.0) Arbitrary requirements
	// Ideally, this would be written as:
	// associatedtype DeltaIndices: Collection where DeltaIndices.Iterator.Element == Snapshot.Index

	/// A type that holds indices of changes in a collection delta.
	associatedtype DeltaIndices: Collection

	/// A Signal that emits subsequent deltas of the collection.
	var signal: Signal<Delta<Snapshot, DeltaIndices>, NoError> { get }

	/// A SignalProducer that emits the latest content of the collection as a
	/// delta when started, followed by all subsequent deltas of the collection.
	var producer: SignalProducer<Delta<Snapshot, DeltaIndices>, NoError> { get }
}

public protocol OrderedReactiveCollection: ReactiveCollection {
	/// A type that snapshots the content of the collection at an instance of
	/// time.
	associatedtype Snapshot: RandomAccessCollection

	/// A type that holds indices of changes in a collection delta.
	associatedtype DeltaIndices: BidirectionalIndexCollection
}
