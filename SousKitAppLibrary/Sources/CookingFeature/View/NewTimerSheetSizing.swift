import SwiftUI

/// The form sheet an iPad presents, no wider than a width.
struct NewTimerSheetSizing: PresentationSizing {
    let maxWidth: Double

    func proposedSize(
        for root: PresentationSizingRoot,
        context: PresentationSizingContext
    ) -> ProposedViewSize {
        let form = FormPresentationSizing.form.proposedSize(for: root, context: context)

        return ProposedViewSize(
            width: form.width.map { min($0, maxWidth) },
            height: form.height
        )
    }
}
