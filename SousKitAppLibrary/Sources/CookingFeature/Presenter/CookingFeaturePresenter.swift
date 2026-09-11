struct CookingFeaturePresenter: CookingFeaturePresenterProtocol {
    private let handler: CookingFeatureHandler
    private let idleTimer: IdleTimer
    private let viewModel: CookingFeatureViewModel

    init(
        handler: CookingFeatureHandler,
        idleTimer: IdleTimer,
        viewModel: CookingFeatureViewModel
    ) {
        self.handler = handler
        self.idleTimer = idleTimer
        self.viewModel = viewModel
    }

    func viewDidAppear() {
        idleTimer.setDisabled(true)
    }

    func viewDidDisappear() {
        idleTimer.setDisabled(false)
    }

    func didTapExit() {
        viewModel.isConfirmingExit = true
    }

    func didChangeIsConfirmingExit(_ isConfirming: Bool) {
        viewModel.isConfirmingExit = isConfirming
    }

    func didConfirmExit() {
        viewModel.isConfirmingExit = false
        handler.cookingFeatureDidExit()
    }
}
