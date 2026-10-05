@testable import CookingFeature

extension CookingFeaturePresenter {
    /// A presenter on spies, driving the given view model.
    @MainActor
    static func stubbed(
        viewModel: CookingFeatureViewModel,
        handler: CookingFeatureHandler = CookingFeatureHandlerSpy(),
        idleTimer: IdleTimer = IdleTimerSpy(),
        restoration: CookingFeatureRestoration? = nil,
        timerScheduler: TimerScheduler = TimerSchedulerSpy()
    ) -> Self {
        Self(
            handler: handler,
            idleTimer: idleTimer,
            restoration: restoration,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
    }
}
