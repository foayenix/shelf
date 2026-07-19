import Foundation
import XCTest
@testable import ShelfKit

final class OrphanNotesTests: ShelfKitTestCase {

    func testAdoptsFilesMissingFromIndex() throws {
        let existing = try store.createNote(body: "already indexed", source: .paste)
        let essays = try store.createCollection(name: "Essays")

        // Simulate a note file that arrived from the iCloud mirror.
        let orphanId = UUID()
        try Data("# Arrived from the cloud\n\nbody".utf8)
            .write(to: paths.noteFile(for: orphanId))

        let adopted = try store.adoptOrphanNotes()

        XCTAssertEqual(adopted.map(\.id), [orphanId])
        XCTAssertEqual(adopted.first?.title, "Arrived from the cloud")
        XCTAssertEqual(adopted.first?.source, .import)
        XCTAssertNil(adopted.first?.collectionId, "orphans land in the Inbox")

        let reloaded = try freshStore()
        XCTAssertEqual(reloaded.index.notes.count, 2)
        XCTAssertEqual(try reloaded.note(id: existing.id).title, "already indexed",
                       "existing entries stay untouched")
        XCTAssertEqual(reloaded.collections.map(\.id), [essays.id],
                       "collections survive, unlike a full rebuild")
    }

    func testNoOpWhenNothingIsOrphaned() throws {
        _ = try store.createNote(body: "indexed", source: .paste)
        XCTAssertTrue(try store.adoptOrphanNotes().isEmpty)
        XCTAssertEqual(store.index.notes.count, 1)
    }
}
