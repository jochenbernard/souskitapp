@testable import FileRecipeLibrary
import Foundation
import SousKit
import Testing

@Suite("Recipe summary cache")
final class RecipeSummaryCacheTests {
    private let parser = SousParser()

    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeSummaryCacheTests")
    }

    private func record(title: String) -> RecipeSummaryRecord {
        RecipeSummaryRecord(
            recipe: parser.parseRecipe("---\ntitle: \(title)\n---").value,
            modificationDate: Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        )
    }

    @Test("nothing is kept before anything is saved")
    func empty() {
        #expect(directory.summaryCache.load().isEmpty)
    }

    @Test("what is saved loads again, dates exactly as kept")
    func roundTrip() {
        let records = ["crepes.sous": record(title: "Crepes"), "brioche.sous": record(title: "Brioche")]

        directory.summaryCache.save(records)

        #expect(directory.summaryCache.load() == records)
    }

    @Test("the summaries are kept outside the recipe directory")
    func outsideTheDirectory() throws {
        directory.summaryCache.save(["crepes.sous": record(title: "Crepes")])

        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.url.path(percentEncoded: false)).isEmpty)
        #expect(FileManager.default.fileExists(atPath: directory.summaryCacheURL.path(percentEncoded: false)))
    }

    @Test("summaries kept for another directory are not loaded")
    func otherDirectory() throws {
        let other = try TemporaryDirectory(named: "RecipeSummaryCacheTests")
        RecipeSummaryCache(recipeDirectory: other.recipeDirectory, fileURL: directory.summaryCacheURL)
            .save(["crepes.sous": record(title: "Crepes")])

        #expect(directory.summaryCache.load().isEmpty)
    }

    @Test("a cache made for another directory since leaves this one writing nothing")
    func replacedByOtherDirectory() throws {
        let other = try TemporaryDirectory(named: "RecipeSummaryCacheTests")
        let cache = directory.summaryCache
        let otherCache = RecipeSummaryCache(recipeDirectory: other.recipeDirectory, fileURL: directory.summaryCacheURL)
        otherCache.save(["brioche.sous": record(title: "Brioche")])

        cache.save(["crepes.sous": record(title: "Crepes")])

        #expect(otherCache.load() == ["brioche.sous": record(title: "Brioche")])
    }

    @Test("a cache made for the same directory since leaves this one writing")
    func replacedBySameDirectory() {
        let cache = directory.summaryCache
        _ = directory.summaryCache

        cache.save(["crepes.sous": record(title: "Crepes")])

        #expect(directory.summaryCache.load() == ["crepes.sous": record(title: "Crepes")])
    }

    @Test("a cache the system cleared loads as nothing")
    func cleared() throws {
        directory.summaryCache.save(["crepes.sous": record(title: "Crepes")])
        try FileManager.default.removeItem(at: directory.summaryCacheURL)

        #expect(directory.summaryCache.load().isEmpty)
    }

    @Test("clearing removes the summaries, and leaves a cache made before writing nothing")
    func clearing() {
        let cache = directory.summaryCache
        cache.save(["crepes.sous": record(title: "Crepes")])

        RecipeSummaryCache.clear(fileURL: directory.summaryCacheURL)
        cache.save(["brioche.sous": record(title: "Brioche")])

        #expect(!FileManager.default.fileExists(atPath: directory.summaryCacheURL.path(percentEncoded: false)))
    }

    @Test("a cache made after clearing keeps summaries again")
    func keepingAfterClearing() {
        directory.summaryCache.save(["crepes.sous": record(title: "Crepes")])
        RecipeSummaryCache.clear(fileURL: directory.summaryCacheURL)

        directory.summaryCache.save(["brioche.sous": record(title: "Brioche")])

        #expect(directory.summaryCache.load() == ["brioche.sous": record(title: "Brioche")])
    }

    @Test("a cache that cannot be read loads as nothing")
    func unreadable() throws {
        try Data("not a cache".utf8).write(to: directory.summaryCacheURL)

        #expect(directory.summaryCache.load().isEmpty)
    }
}
