import SwiftUI

/// The corner radius of a row or a callout.
@propertyWrapper
struct LineContainerRadius: DynamicProperty {
    /// The height of one `.body` line, before Dynamic Type scales it.
    @ScaledMetric(relativeTo: .body) private var scaledBodyLineHeight = 20.3

    var wrappedValue: CGFloat {
        (scaledBodyLineHeight + SousSpacing.medium * 2.0) / 2.0
    }
}
