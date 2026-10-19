@testable import KitchenFeature

/// A handler that keeps what the kitchen last reported open, and counts its restores, with something open over the
/// kitchen where a test says so.
@MainActor
final class KitchenFeatureHandlerStub: KitchenFeatureHandler {
    var kitchenFeatureIsCovered = false

    /// What the kitchen last reported open, which is what it was built to open again until it reports.
    private(set) var restoration: KitchenFeatureRestoration?
    private(set) var restoreCount = 0

    init(restoration: KitchenFeatureRestoration? = nil) {
        self.restoration = restoration
    }

    func kitchenFeatureDidChangeRestoration(_ restoration: KitchenFeatureRestoration?) {
        self.restoration = restoration
    }

    func kitchenFeatureDidRestore() {
        restoreCount += 1
    }
}
