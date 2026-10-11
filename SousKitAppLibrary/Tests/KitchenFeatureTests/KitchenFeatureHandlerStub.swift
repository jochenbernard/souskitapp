@testable import KitchenFeature

/// A handler that keeps what the kitchen last reported open, and counts its restores.
@MainActor
final class KitchenFeatureHandlerStub: KitchenFeatureHandler {
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
