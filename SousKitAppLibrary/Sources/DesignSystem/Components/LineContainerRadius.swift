import SwiftUI

/// The corner radius of every box: a row, a callout, a card, and the rows that share one.
@propertyWrapper
public struct LineContainerRadius: DynamicProperty {
    /// The height of one `.body` line, before Dynamic Type scales it.
    @ScaledMetric(relativeTo: .body) private var scaledBodyLineHeight = 20.3

    /// The radius, for the text size in force.
    public var wrappedValue: CGFloat {
        (scaledBodyLineHeight + SousSpacing.medium * 2.0) / 2.0
    }

    /// Creates the radius.
    public init() {}
}
