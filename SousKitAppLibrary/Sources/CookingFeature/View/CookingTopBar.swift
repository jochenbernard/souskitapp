import DesignSystem
import SwiftUI

/// The cooking screen's bar: the way out, the recipe's title, and the way to a new timer.
struct CookingTopBar: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let title: String
    private let isConfirmingExit: Bool

    // The room the system takes at the bar's leading corner, for the controls of an iPad window.
    @State private var leadingCornerInset = 0.0

    init(
        presenter: CookingFeaturePresenterProtocol,
        title: String,
        isConfirmingExit: Bool
    ) {
        self.presenter = presenter
        self.title = title
        self.isConfirmingExit = isConfirmingExit
    }

    var body: some View {
        HStack(spacing: SousSpacing.large) {
            exitButton
                .padding(.leading, leadingCornerInset)
                .frame(maxWidth: .infinity, alignment: .leading)

            titleText

            newTimerButton
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.bottom, SousSpacing.small)
        .onGeometryChange(for: CGFloat.self, of: \.containerCornerInsets.topLeading.width) { width in
            leadingCornerInset = width
        }
    }

    private var exitButton: some View {
        // The role's own label carries the system's "Close" for VoiceOver, in every language.
        Button(role: .close, action: presenter.didTapExit)
            .buttonStyle(.glassCircle)
            .confirmationDialog(
                Text("Are you sure you want to stop cooking?", bundle: .module),
                isPresented: isConfirmingExitBinding,
                titleVisibility: .visible,
                actions: { confirmExitButton }
            )
    }

    private var confirmExitButton: some View {
        Button(role: .destructive, action: presenter.didConfirmExit) {
            Text("Stop cooking", bundle: .module)
        }
    }

    private var titleText: some View {
        Text(verbatim: title)
            .font(.headline)
            .lineLimit(1)
            // The buttons share what the title leaves evenly, which centres it until one of them runs out of room.
            .layoutPriority(1.0)
            .accessibilityAddTraits(.isHeader)
    }

    private var newTimerButton: some View {
        Button(action: presenter.didTapNewTimer) {
            Label(
                title: { Text("New timer", bundle: .module) },
                icon: { Image(systemName: "timer") }
            )
        }
        .buttonStyle(.glassCircle)
    }

    private var isConfirmingExitBinding: Binding<Bool> {
        Binding(
            get: { isConfirmingExit },
            set: { presenter.didChangeIsConfirmingExit($0) }
        )
    }
}

#Preview("Cooking top bar") {
    CookingTopBar(
        presenter: CookingFeaturePresenterStub(),
        title: "Quiche Lorraine",
        isConfirmingExit: false
    )
    .frame(maxHeight: .infinity, alignment: .top)
    .sousPage()
}
