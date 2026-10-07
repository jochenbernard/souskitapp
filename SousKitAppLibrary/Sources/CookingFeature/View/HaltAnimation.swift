import SwiftUI

/// Takes over from any animation still moving a value, and ends at once.
private struct HaltAnimation: CustomAnimation {
    func animate<V: VectorArithmetic>(
        value _: V,
        time _: TimeInterval,
        context _: inout AnimationContext<V>
    ) -> V? {
        nil
    }

    func shouldMerge<V: VectorArithmetic>(
        previous _: Animation,
        value _: V,
        time _: TimeInterval,
        context _: inout AnimationContext<V>
    ) -> Bool {
        true
    }
}

extension Animation {
    /// Stops any animation still moving a value, which a change made without an animation leaves running on top of the
    /// new value, and puts the value where it is set from the next frame: the first still shows where it starts from.
    static let halt = Animation(HaltAnimation())
}
