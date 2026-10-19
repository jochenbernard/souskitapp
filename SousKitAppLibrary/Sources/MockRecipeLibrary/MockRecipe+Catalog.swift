import RecipeLibrary

extension MockRecipe {
    #if DEBUG
    /// Every file in the folder the repository stands in for, ordered by path as a folder lists them.
    ///
    /// The ten examples of the specification sit at the top among recipes that are empty, malformed, annotated in every
    /// way the format allows, timed in seconds, or all ten examples in one. The folders under them hold examples again,
    /// down to three levels deep, under the same file names as those at the top. One folder holds only folders, one
    /// holds no recipe, and one is hidden.
    ///
    /// The pictures sit in `images` folders beside the recipes naming them. One cannot be read, one starts out in
    /// iCloud, and some recipes name one that is missing, out of the folder, or on the web.
    static let all: [MockRecipe] = [
        MockRecipe(path: ".archive/vinaigrette.sous", text: MockRecipes.vinaigrette),
        MockRecipe(path: "Baking/brioche.sous", text: MockRecipes.brioche),
        MockRecipe(
            path: "Baking/crepes.sous",
            text: MockRecipes.crepes,
            availability: .notDownloaded
        ),
        MockRecipe(path: "Baking/images/brioche.jpg", picture: MockPicture(hue: 0.11, aspectRatio: 1.0)),
        MockRecipe(path: "Baking/madeleines.sous", text: MockRecipes.madeleines),
        MockRecipe(
            path: """
            boeuf-bourguignon-bouillabaisse-brioche-crepes-croque-monsieur-gratin-dauphinois-madeleines-\
            moules-marinieres-quiche-lorraine-and-vinaigrette.sous
            """,
            text: MockRecipes.everyExample
        ),
        MockRecipe(path: "boeuf-bourguignon.sous", text: MockRecipes.boeufBourguignon),
        MockRecipe(path: "bouillabaisse.sous", text: MockRecipes.bouillabaisse),
        MockRecipe(path: "brioche.sous", text: MockRecipes.brioche),
        MockRecipe(
            path: "crepes.sous",
            text: MockRecipes.crepes,
            availability: .notDownloaded
        ),
        MockRecipe(path: "croque-monsieur.sous", text: MockRecipes.croqueMonsieur),
        MockRecipe(path: "Dinner/moules-marinieres.sous", text: MockRecipes.moulesMarinieres),
        MockRecipe(path: "Dinner/Provencal/bouillabaisse.sous", text: MockRecipes.bouillabaisse),
        MockRecipe(path: "empty.sous", text: MockRecipes.empty),
        MockRecipe(path: "French/Classic/boeuf-bourguignon.sous", text: MockRecipes.boeufBourguignon),
        MockRecipe(
            path: "French/Classic/images/boeuf-bourguignon.jpg",
            picture: MockPicture(hue: 0.97, aspectRatio: 4.0 / 3.0)
        ),
        MockRecipe(path: "French/Classic/quiche-lorraine.sous", text: MockRecipes.quicheLorraine),
        MockRecipe(
            path: "French/Comfort food/gratin-dauphinois.sous",
            text: MockRecipes.gratinDauphinois,
            availability: .downloading
        ),
        MockRecipe(
            path: "French/Comfort food/images/gratin-dauphinois.jpg",
            picture: MockPicture(hue: 0.14, aspectRatio: 4.0 / 3.0)
        ),
        MockRecipe(
            path: "gratin-dauphinois.sous",
            text: MockRecipes.gratinDauphinois,
            availability: .downloading
        ),
        MockRecipe(path: "header-only.sous", text: MockRecipes.headerOnly),
        MockRecipe(path: "images/boeuf-bourguignon.jpg", picture: MockPicture(hue: 0.02, aspectRatio: 16.0 / 9.0)),
        MockRecipe(path: "images/bouillabaisse.jpg", picture: MockPicture(hue: 0.06, aspectRatio: 4.0 / 3.0)),
        MockRecipe(path: "images/brioche.jpg", picture: MockPicture(hue: 0.1, aspectRatio: 3.0 / 4.0)),
        MockRecipe(path: "images/crepes.jpg", picture: MockPicture(hue: 0.16, aspectRatio: 3.0 / 2.0)),
        MockRecipe(path: "images/croque-monsieur.jpg", picture: nil),
        MockRecipe(
            path: "images/gratin-dauphinois.jpg",
            picture: MockPicture(hue: 0.13, aspectRatio: 4.0 / 3.0),
            availability: .notDownloaded
        ),
        MockRecipe(path: "images/moules-marinieres.jpg", picture: MockPicture(hue: 0.62, aspectRatio: 4.0 / 3.0)),
        MockRecipe(path: "images/vinaigrette.jpg", picture: MockPicture(hue: 0.3, aspectRatio: 1.0)),
        MockRecipe(path: "Lunch/French/Classic/croque-monsieur.sous", text: MockRecipes.croqueMonsieur),
        MockRecipe(path: "madeleines.sous", text: MockRecipes.madeleines),
        MockRecipe(path: "malformed.sous", text: MockRecipes.malformed),
        MockRecipe(path: "moules-marinieres.sous", text: MockRecipes.moulesMarinieres),
        MockRecipe(path: "quiche-lorraine.sous", text: MockRecipes.quicheLorraine),
        MockRecipe(path: "short-timers.sous", text: MockRecipes.shortTimers),
        MockRecipe(path: "steps-only.sous", text: MockRecipes.stepsOnly),
        MockRecipe(
            path: "unreachable.sous",
            text: nil,
            availability: .notDownloaded
        ),
        MockRecipe(path: "unterminated-header.sous", text: MockRecipes.unterminatedHeader),
        MockRecipe(path: "unusual-annotations.sous", text: MockRecipes.unusualAnnotations),
        MockRecipe(path: "vinaigrette.sous", text: MockRecipes.vinaigrette)
    ]
    #else
    /// No files: they are there for trying the app where no folder can be picked, which only a debug build offers.
    static let all: [MockRecipe] = []
    #endif
}
