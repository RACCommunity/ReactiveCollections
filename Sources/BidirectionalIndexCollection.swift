import Foundation

public protocol BidirectionalIndexCollection: BidirectionalCollection {
	// FIXME: (Swift 4.0) Arbitrary requirements
	// Ideally, this would be written as:
	// associatedtype Iterator where Iterator.Element: Strideable, Iterator.Element.Stride: SignedInteger
	associatedtype Iterator

	// FIXME: (Swift 4.0) Arbitrary requirements
	// Ideally, this would be written as:
	// associatedtype RangeView: BidirectionalCollection where RangeView.Iterator.Element == CountableRange<Iterator.Element>
	associatedtype RangeView: BidirectionalCollection

	var rangeView: RangeView { get }
}

extension IndexSet: BidirectionalIndexCollection {}
