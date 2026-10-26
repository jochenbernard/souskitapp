import DesignSystem
import SwiftUI

/// A showcase recipe as the kitchen shows a recipe: its picture, its title, and how long it takes.
struct OnboardingShowcaseCard: View {
    // The language the screen is written in, which is the one it reads a length of time in.
    private static let displayLocale = Locale(identifier: Bundle.module.preferredLocalizations.first ?? "en")

    private let recipe: OnboardingShowcaseRecipe

    init(_ recipe: OnboardingShowcaseRecipe) {
        self.recipe = recipe
    }

    var body: some View {
        SousCard(
            title: recipe.title,
            picture: { picture },
            detail: { Text(verbatim: totalTime) }
        )
    }

    // Filling the card's picture and cropped to it, as the kitchen crops a recipe's picture.
    private var picture: some View {
        Color.clear
            .overlay {
                Image(decorative: recipe.pictureName, bundle: .module)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }

    private var totalTime: String {
        recipe.totalTime.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated).locale(Self.displayLocale))
    }
}

#Preview("Showcase cards") {
    HStack(alignment: .top, spacing: SousSpacing.medium) {
        ForEach(OnboardingShowcaseRecipe.all) { recipe in
            OnboardingShowcaseCard(recipe)
        }
    }
    .fixedSize(horizontal: false, vertical: true)
    .sousPagePadding()
    .frame(maxHeight: .infinity)
    .sousPage()
}
