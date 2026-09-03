import XCTest
@testable import ShelfKit

/// Covers what happens to `index.json` when it can't be trusted — the paths that
/// decide whether a user keeps their collections, favourites and edited titles.
final class IndexRecoveryTests: ShelfKitTestCase {
    func testCorruptIndexIsQuarantinedRatherThanDeleted() throws {
        _ = try store.createNote(body: sampleMarkdown, source: .paste)
        let original = try String(contentsOf: paths.indexFile, encoding: .utf8)
        try Data("not json {{{".utf8).write(to: paths.indexFile)

        _ = try freshStore()

        let quarantined = try FileManager.default
            .contentsOfDirectory(atPath: paths.shelfDirectory.path)
            .filter { $0.hasPrefix("index-corrupt-") }
        XCTAssertEqual(quarantined.count, 1, "the unreadable bytes must be kept for recovery")
        XCTAssertNotEqual(
            try String(contentsOf: paths.shelfDirectory.appendingPathComponent(quarantined[0]), encoding: .utf8),
            original,
            "the quarantined file is the broken one, not the good one"
        )
    }

    func testIndexFromANewerSchemaIsRefusedNotFlattened() throws {
        let collection = try store.createCollection(name: "Essays")
        _ = try store.createNote(body: sampleMarkdown, collectionId: collection.id, source: .paste)

        var ahead = store.index
        ahead.schemaVersion = ShelfIndex.currentSchemaVersion + 1
        try ShelfIndex.encoder().encode(ahead).write(to: paths.indexFile)

        XCTAssertThrowsError(try freshStore()) { error in
            XCTAssertEqual(error as? ShelfStoreError,
                           .indexFromNewerVersion(ShelfIndex.currentSchemaVersion + 1))
        }
        let onDisk = try ShelfIndex.decoder().decode(ShelfIndex.self, from: Data(contentsOf: paths.indexFile))
        XCTAssertEqual(onDisk.collections.count, 1, "a newer index must be left exactly as it was")
    }

    func testMutationRefusesToClobberAnUnreadableIndex() throws {
        _ = try store.createNote(body: "first", source: .paste)
        try Data("not json {{{".utf8).write(to: paths.indexFile)

        XCTAssertThrowsError(try store.createNote(body: "second", source: .paste)) { error in
            XCTAssertEqual(error as? ShelfStoreError, .indexUnreadable)
        }
        XCTAssertEqual(try String(contentsOf: paths.indexFile, encoding: .utf8), "not json {{{")
    }

    func testFailedMutationLeavesNoOrphanBodyFile() throws {
        try Data("not json {{{".utf8).write(to: paths.indexFile)
        XCTAssertThrowsError(try store.createNote(body: "second", source: .paste))

        let files = try FileManager.default.contentsOfDirectory(atPath: paths.notesDirectory.path)
        XCTAssertTrue(files.isEmpty, "a note whose index entry never landed must not leave a .md behind")
    }

    func testCollectionRenameFollowsTheIdNotThePosition() throws {
        let first = try store.createCollection(name: "First")
        let second = try store.createCollection(name: "Second")

        // Another process removes the earlier collection behind our back.
        let other = try freshStore()
        try other.deleteCollection(first.id)

        let renamed = try store.renameCollection(second.id, to: "Renamed")
        XCTAssertEqual(renamed.name, "Renamed")
        try store.reloadFromDisk()
        XCTAssertEqual(store.collections.map(\.name), ["Renamed"],
                       "the surviving collection is the one that got renamed")
    }

    func testCollectionCreatedAfterAnotherProcessKeepsDistinctSortOrder() throws {
        _ = try store.createCollection(name: "App")
        let other = try freshStore()
        _ = try other.createCollection(name: "Extension")

        _ = try store.createCollection(name: "App again")
        try store.reloadFromDisk()
        let orders = store.collections.map(\.sortOrder)
        XCTAssertEqual(Set(orders).count, orders.count, "sort order is assigned against the index on disk")
    }

    func testMoveToCollectionDeletedByAnotherProcessThrows() throws {
        let collection = try store.createCollection(name: "Essays")
        let note = try store.createNote(body: "body", source: .paste)

        let other = try freshStore()
        try other.deleteCollection(collection.id)

        XCTAssertThrowsError(try store.moveNote(note.id, to: collection.id)) { error in
            XCTAssertEqual(error as? ShelfStoreError, .collectionNotFound(collection.id))
        }
    }
}
