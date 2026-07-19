import Foundation
import XCTest
@testable import ShelfKit

final class ShelfMigratorTests: XCTestCase {
    private var sourceRoot: URL!
    private var destinationRoot: URL!

    override func setUpWithError() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfMigratorTests-\(UUID().uuidString)", isDirectory: true)
        sourceRoot = base.appendingPathComponent("documents")
        destinationRoot = base.appendingPathComponent("appgroup")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: sourceRoot.deletingLastPathComponent())
    }

    func testMovesShelfToNewRoot() throws {
        let source = ShelfPaths(root: sourceRoot)
        let old = try ShelfStore(paths: source)
        let collection = try old.createCollection(name: "Essays")
        let note = try old.createNote(body: "migrated body", collectionId: collection.id, source: .paste)

        let destination = ShelfPaths(root: destinationRoot)
        try ShelfMigrator.migrate(from: source, to: destination)

        let migrated = try ShelfStore(paths: destination)
        XCTAssertEqual(try migrated.body(of: note.id), "migrated body")
        XCTAssertEqual(migrated.collections.map(\.name), ["Essays"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.shelfDirectory.path),
                       "the old location must be gone so migration can't run twice")
    }

    func testNoOpWhenSourceMissing() throws {
        let destination = ShelfPaths(root: destinationRoot)
        _ = try ShelfStore(paths: destination)
        try ShelfMigrator.migrate(from: ShelfPaths(root: sourceRoot), to: destination)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.indexFile.path))
    }

    func testNeverClobbersDestinationWithNotes() throws {
        let source = ShelfPaths(root: sourceRoot)
        _ = try ShelfStore(paths: source).createNote(body: "old note", source: .paste)

        let destination = ShelfPaths(root: destinationRoot)
        let existing = try ShelfStore(paths: destination)
        let kept = try existing.createNote(body: "already here", source: .shareExtension)

        try ShelfMigrator.migrate(from: source, to: destination)

        let after = try ShelfStore(paths: destination)
        XCTAssertEqual(try after.body(of: kept.id), "already here")
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.shelfDirectory.path),
                      "source must remain untouched when migration is skipped")
    }

    func testReplacesEmptyFreshDestinationStore() throws {
        let source = ShelfPaths(root: sourceRoot)
        let note = try ShelfStore(paths: source).createNote(body: "the real data", source: .paste)

        // A store that was initialised (index.json written) but never used.
        let destination = ShelfPaths(root: destinationRoot)
        _ = try ShelfStore(paths: destination)

        try ShelfMigrator.migrate(from: source, to: destination)
        XCTAssertEqual(try ShelfStore(paths: destination).body(of: note.id), "the real data")
    }
}
