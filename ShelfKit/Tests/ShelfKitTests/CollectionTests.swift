import Foundation
import XCTest
@testable import ShelfKit

final class CollectionTests: ShelfKitTestCase {

    func testCreateAssignsIncrementingSortOrder() throws {
        let essays = try store.createCollection(name: "Essays")
        let cooking = try store.createCollection(name: "Cooking", emoji: "🍳")

        XCTAssertEqual(essays.sortOrder, 0)
        XCTAssertEqual(cooking.sortOrder, 1)
        XCTAssertEqual(try freshStore().collections.map(\.name), ["Essays", "Cooking"])
    }

    func testRenamePersists() throws {
        let c = try store.createCollection(name: "Esays")
        _ = try store.renameCollection(c.id, to: "Essays")
        XCTAssertEqual(try freshStore().collections.first?.name, "Essays")
    }

    func testDeleteCollectionSendsNotesToInbox() throws {
        let essays = try store.createCollection(name: "Essays")
        let note = try store.createNote(body: "shelved", collectionId: essays.id, source: .paste)

        try store.deleteCollection(essays.id)

        let reloaded = try freshStore()
        XCTAssertTrue(reloaded.collections.isEmpty)
        XCTAssertNil(try reloaded.note(id: note.id).collectionId,
                     "deleting a shelf must never delete its notes")
        XCTAssertEqual(try reloaded.body(of: note.id), "shelved")
    }

    func testDeleteMissingCollectionThrows() {
        let ghost = UUID()
        XCTAssertThrowsError(try store.deleteCollection(ghost)) {
            XCTAssertEqual($0 as? ShelfStoreError, .collectionNotFound(ghost))
        }
    }

    func testMoveNoteBetweenShelvesAndBackToInbox() throws {
        let essays = try store.createCollection(name: "Essays")
        let note = try store.createNote(body: "wandering note", source: .paste)

        _ = try store.moveNote(note.id, to: essays.id)
        XCTAssertEqual(try store.note(id: note.id).collectionId, essays.id)

        _ = try store.moveNote(note.id, to: nil)
        XCTAssertNil(try store.note(id: note.id).collectionId)
    }

    func testMoveToUnknownCollectionThrows() throws {
        let note = try store.createNote(body: "stuck", source: .paste)
        XCTAssertThrowsError(try store.moveNote(note.id, to: UUID()))
    }

    func testReorderCollections() throws {
        let a = try store.createCollection(name: "A")
        let b = try store.createCollection(name: "B")
        let c = try store.createCollection(name: "C")

        try store.reorderCollections([c.id, a.id, b.id])
        XCTAssertEqual(try freshStore().collections.map(\.name), ["C", "A", "B"])
    }
}
