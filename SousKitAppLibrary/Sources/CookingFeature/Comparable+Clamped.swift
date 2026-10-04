extension Comparable {
    /// The value, held within a range.
    ///
    /// - Parameter range: The range the value is held within.
    /// - Returns: The value, or the range's bound it lies beyond.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
