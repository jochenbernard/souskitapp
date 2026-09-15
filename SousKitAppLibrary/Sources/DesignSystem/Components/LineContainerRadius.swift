import SwiftUI

/// The corner radius of a container padded ``SousSpacing/medium`` around `.body` lines: a capsule's
/// where it holds one line, and kept where its text wraps.
///
/// It follows Dynamic Type, so the curve holds at every text size.
@propertyWrapper
struct LineContainerRadius: DynamicProperty {
    /// The height of one `.body` line, before Dynamic Type scales it.
    @ScaledMetric(relativeTo: .body) private var scaledBodyLineHeight = 20.3

    var wrappedValue: CGFloat {
        (scaledBodyLineHeight + SousSpacing.medium * 2.0) / 2.0
    }
}
