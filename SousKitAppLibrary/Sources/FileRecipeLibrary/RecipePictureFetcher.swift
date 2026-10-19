import RecipeLibrary

/// Fetches from iCloud the pictures listed recipes name, without waiting for anything to show them, as new or changed
/// recipes are fetched.
///
/// A picture is fetched once for each way it is listed, so one iCloud fails to fetch is asked for again only once it is
/// listed differently. Nothing is ever evicted.
@MainActor
final class RecipePictureFetcher {
    private let reader: RecipePictureReader

    // By picture id, each as it was listed when its fetch started.
    private var fetches: [String: Task<Void, Never>] = [:]
    private var fetchedPictures: Set<RecipePicture> = []

    /// Creates a fetcher.
    ///
    /// - Parameter reader: What the pictures are fetched with.
    nonisolated init(reader: RecipePictureReader) {
        self.reader = reader
    }

    deinit {
        fetches.values.forEach({ $0.cancel() })
    }

    /// Fetches each picture the recipes name that is not on the device, on its own so one that never arrives holds up
    /// no other, and gives up on the fetches of pictures no recipe names any more.
    ///
    /// - Parameters:
    ///   - listedRecipes: The recipes listed now.
    ///   - onLanding: Called each time a picture is on the device.
    func fetchPictures(
        namedIn listedRecipes: [ListedRecipe],
        onLanding: @escaping @MainActor () -> Void
    ) {
        let namedPictures = Set(listedRecipes.compactMap(\.entry.picture))
        let namedIDs = Set(namedPictures.map(\.id))

        for (id, fetch) in fetches where !namedIDs.contains(id) {
            fetch.cancel()
            fetches[id] = nil
        }

        fetchedPictures = fetchedPictures.filter({ namedIDs.contains($0.id) })

        let picturesToFetch = namedPictures.filter { picture in
            picture.availability != .downloaded && fetches[picture.id] == nil && !fetchedPictures.contains(picture)
        }

        for picture in picturesToFetch {
            fetchedPictures.insert(picture)
            fetches[picture.id] = Task { [weak self, reader] in
                let hasLanded = (try? await reader.fetch(picture)) != nil

                guard !Task.isCancelled else {
                    return
                }

                self?.fetches[picture.id] = nil

                if hasLanded {
                    onLanding()
                }
            }
        }
    }

    /// Gives up on every fetch, and forgets which pictures were fetched.
    func stop() {
        fetches.values.forEach({ $0.cancel() })
        fetches = [:]
        fetchedPictures = []
    }
}
