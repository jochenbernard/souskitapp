import DesignSystem
import SwiftUI

/// The cooking screen's bar: the way out, and the recipe's title.
struct CookingTopBar: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let title: String
    private let isConfirmingExit: Bool

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
        HStack {
            exitButton

            Spacer(minLength: 0.0)
        }
        .overlay {
            titleText
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.bottom, SousSpacing.small)
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
            // Clear of the exit button, and as far from the other side, so the title stays centred.
            .padding(.horizontal, SousSpacing.page)
            .accessibilityAddTraits(.isHeader)
    }

    private var isConfirmingExitBinding: Binding<Bool> {
        Binding(
            get: { isConfirmingExit },
            set: { presenter.didChangeIsConfirmingExit($0) }
        )
    }
}

#Preview("Cooking top bar") {
    VStack {
        CookingTopBar(
            presenter: CookingFeaturePresenterStub(),
            title: "Quiche Lorraine",
            isConfirmingExit: false
        )

        Spacer()
    }
    .sousPage()
}
