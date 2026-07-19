import Foundation
import XCTest
@testable import ShelfKit

final class ShelfStoreTests: ShelfKitTestCase {

    // MARK: Save / load

    func testCreateNoteWritesFileAndIndexEntry() throws {
        let note = try store.createNote(body: sampleMarkdown, source: .paste)

        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.noteFile(for: note.id).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.indexFile.path))
        XCTAssertEqual(note.title, "A short history of the semicolon")
        XCTAssertNil(note.collectionId, "uncategorised notes belong to the Inbox")
        XCTAssertEqual(note.source, .paste)
        XCTAssertFalse(note.favourite)
        XCTAssertEqual(note.wordCount, WordCount.count(sampleMarkdown))
    }

    func testBodySurvivesRoundTripExactly() throws {
        let note = try store.createNote(body: sampleMarkdown, source: .shareExtension)
        let reloaded = try freshStore()

        XCTAssertEqual(try reloaded.body(of: note.id), sampleMarkdown,
                       "raw markdown must be stored byte-for-byte as captured")
        XCTAssertEqual(try reloaded.note(id: note.id), note)
    }

    func testExplicitTitleWinsOverDetection() throws {
        let note = try store.createNote(body: sampleMarkdown, title: "My title", source: .paste)
        XCTAssertEqual(note.title, "My title")
    }

    func testCreateEmptyNoteThrows() {
        XCTAssertThrowsError(try store.createNote(body: "   \n\n  ", source: .paste)) {
            XCTAssertEqual($0 as? ShelfStoreError, .emptyCapture)
        }
    }

    // MARK: Edit

    func testUpdateTitlePersists() throws {
        let note = try store.createNote(body: "hello world", source: .paste)
        _ = try store.updateTitle("Renamed", for: note.id)

        XCTAssertEqual(try freshStore().note(id: note.id).title, "Renamed")
    }

    func testUpdateBodyRewritesFileAndWordCount() throws {
        let note = try store.createNote(body: "one two three", source: .paste)
        _ = try store.updateBody("just five words in this body", for: note.id)

        let reloaded = try freshStore()
        XCTAssertEqual(try reloaded.body(of: note.id), "just five words in this body")
        XCTAssertEqual(try reloaded.note(id: note.id).wordCount, 6)
    }

    func testUpdateBodyToEmptyThrows() throws {
        let note = try store.createNote(body: "keep me", source: .paste)
        XCTAssertThrowsError(try store.updateBody("  ", for: note.id))
        XCTAssertEqual(try store.body(of: note.id), "keep me", "failed edit must not touch the file")
    }

    func testSetFavourite() throws {
        let note = try store.createNote(body: "fav", source: .paste)
        _ = try store.setFavourite(true, for: note.id)
        XCTAssertTrue(try freshStore().note(id: note.id).favourite)
    }

    // MARK: Delete

    func testDeleteNoteRemovesFileAndEntry() throws {
        let note = try store.createNote(body: "delete me", source: .paste)
        try store.deleteNote(note.id)

        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.noteFile(for: note.id).path))
        XCTAssertThrowsError(try freshStore().note(id: note.id))
    }

    func testDeleteMissingNoteThrows() {
        let ghost = UUID()
        XCTAssertThrowsError(try store.deleteNote(ghost)) {
            XCTAssertEqual($0 as? ShelfStoreError, .noteNotFound(ghost))
        }
    }

    // MARK: Listing

    func testNotesFilterByCollectionAndSortNewestFirst() throws {
        let essays = try store.createCollection(name: "Essays")
        let a = try store.createNote(body: "older inbox note", source: .paste)
        _ = try store.createNote(body: "shelved note", collectionId: essays.id, source: .paste)
        // Index dates have whole-second precision; space the second inbox note out
        // so the newest-first ordering is deterministic.
        Thread.sleep(forTimeInterval: 1.1)
        let b = try store.createNote(body: "newer inbox note", source: .paste)

        let inbox = store.notes(in: nil)
        XCTAssertEqual(inbox.map(\.id), [b.id, a.id])
        XCTAssertEqual(store.notes(in: essays.id).count, 1)
    }

    // MARK: Index integrity

    func testIndexIsPortableJSON() throws {
        _ = try store.createNote(body: sampleMarkdown, source: .import)
        let raw = try String(contentsOf: paths.indexFile, encoding: .utf8)

        XCTAssertTrue(raw.contains("\"schemaVersion\""))
        XCTAssertTrue(raw.contains("\"import\""), "source enum must serialise to the brief's names")
        let decoded = try ShelfIndex.decoder().decode(ShelfIndex.self, from: Data(raw.utf8))
        XCTAssertEqual(decoded, store.index)
    }

    func testCorruptIndexRebuildsFromMarkdownFiles() throws {
        let note = try store.createNote(body: sampleMarkdown, source: .paste)
        try Data("not json {{{".utf8).write(to: paths.indexFile)

        let recovered = try freshStore()
        let rebuilt = try recovered.note(id: note.id)
        XCTAssertEqual(rebuilt.title, "A short history of the semicolon",
                       "titles are re-detected from the files")
        XCTAssertEqual(rebuilt.wordCount, note.wordCount)
        XCTAssertEqual(rebuilt.source, .import)
        XCTAssertEqual(try recovered.body(of: note.id), sampleMarkdown)
    }

    func testMissingIndexRebuildsFromMarkdownFiles() throws {
        let note = try store.createNote(body: "plain text note", source: .paste)
        try FileManager.default.removeItem(at: paths.indexFile)

        let recovered = try freshStore()
        XCTAssertEqual(try recovered.note(id: note.id).title, "plain text note")
    }

    func testRebuildIgnoresForeignFiles() throws {
        try Data("junk".utf8).write(to: paths.notesDirectory.appendingPathComponent("readme.txt"))
        try Data("junk".utf8).write(to: paths.notesDirectory.appendingPathComponent("not-a-uuid.md"))
        let rebuilt = try store.rebuildIndex()
        XCTAssertTrue(rebuilt.notes.isEmpty)
    }

    // MARK: Cross-process behaviour (app + share extension)

    func testWriteFromSecondStoreVisibleAfterReload() throws {
        let extensionStore = try freshStore()
        let saved = try extensionStore.createNote(body: "saved from the share sheet", source: .shareExtension)

        try store.reloadFromDisk()
        XCTAssertEqual(try store.note(id: saved.id).source, .shareExtension)
    }

    func testInterleavedWritesFromTwoStoresBothSurvive() throws {
        let extensionStore = try freshStore()
        let fromApp = try store.createNote(body: "from the app", source: .paste)
        let fromExt = try extensionStore.createNote(body: "from the extension", source: .shareExtension)

        try store.reloadFromDisk()
        XCTAssertEqual(try store.note(id: fromApp.id).id, fromApp.id)
        XCTAssertEqual(try store.note(id: fromExt.id).id, fromExt.id,
                       "mutations re-read the index from disk, so writers never clobber each other")
    }
}
