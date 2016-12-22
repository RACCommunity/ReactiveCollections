import ReactiveSwift
import enum Result.NoError

// FIXME: (Swift 4.0?) Generalized Existentials
// Ideally, this would be written as:
// public typealias AnyReactiveCollection<Snapshot, DeltaIndices> = ReactiveCollection where .Snapshot == Snapshot, .DeltaIndices == DeltaIndices
public final class AnyReactiveCollection<Snapshot: Collection, DeltaIndices: Collection>: ReactiveCollection {
	private let _signal: () -> Signal<Delta<Snapshot, DeltaIndices>, NoError>
	private let _producer: () -> SignalProducer<Delta<Snapshot, DeltaIndices>, NoError>

	public var signal: Signal<Delta<Snapshot, DeltaIndices>, NoError> {
		return _signal()
	}

	public var producer: SignalProducer<Delta<Snapshot, DeltaIndices>, NoError> {
		return _producer()
	}

	init<R: ReactiveCollection>(_ base: R) where R.Snapshot == Snapshot, R.DeltaIndices == DeltaIndices	{
		_signal = { base.signal }
		_producer = { base.producer }
	}
}

// FIXME: (Swift 4.0?) Generalized Existentials
// Ideally, this would be written as:
// public typealias AnyReactiveCollection<Snapshot, DeltaIndices> = OrderedReactiveCollection where .Snapshot == Snapshot, .DeltaIndices == DeltaIndices
public final class AnyOrderedReactiveCollection<S: RandomAccessCollection, D: BidirectionalIndexCollection>: OrderedReactiveCollection {
	// FIXME: Swift 3.0.1 cannot infer these paramters. Remove these typealiases
	//        and rename the type parameters back when it is patched.
	public typealias Snapshot = S
	public typealias DeltaIndices = D

	private let _signal: () -> Signal<Delta<S, D>, NoError>
	private let _producer: () -> SignalProducer<Delta<S, D>, NoError>

	public var signal: Signal<Delta<S, D>, NoError> {
		return _signal()
	}

	public var producer: SignalProducer<Delta<S, D>, NoError> {
		return _producer()
	}

	init<R: ReactiveCollection>(_ base: R) where R.Snapshot == S, R.DeltaIndices == DeltaIndices	{
		_signal = { base.signal }
		_producer = { base.producer }
	}
}
