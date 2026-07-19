import Foundation
import XCTest
@testable import ShelfKit

final class CaptureProcessorTests: XCTestCase {

    func testProcessKeepsMarkdownExactly() throws {
        let draft = try CaptureProcessor.process(text: sampleMarkdown)
        XCTAssertEqual(draft.body, sampleMarkdown)
        XCTAssertEqual(draft.title, "A short history of the semicolon")
        XCTAssertFalse(draft.truncated)
    }

    func testEmptyTextThrows() {
        XCTAssertThrowsError(try CaptureProcessor.process(text: "")) {
            XCTAssertEqual($0 as? ShelfStoreError, .emptyCapture)
        }
        XCTAssertThrowsError(try CaptureProcessor.process(text: " \n\t "))
    }

    func testOversizedCaptureTruncatesWithFlag() throws {
        let big = String(repeating: "a", count: CaptureProcessor.maxCharacters + 500)
        let draft = try CaptureProcessor.process(text: big)
        XCTAssertTrue(draft.truncated, "the UI needs this flag to show the warning")
        XCTAssertEqual(draft.body.count, CaptureProcessor.maxCharacters)
    }

    func testExactlyAtLimitIsNotTruncated() throws {
        let body = String(repeating: "b", count: CaptureProcessor.maxCharacters)
        let draft = try CaptureProcessor.process(text: body)
        XCTAssertFalse(draft.truncated)
        XCTAssertEqual(draft.body, body)
    }

    func testURLBecomesOneLineNote() {
        let draft = CaptureProcessor.process(url: URL(string: "https://claude.ai/chat/abc123")!)
        XCTAssertEqual(draft.body, "https://claude.ai/chat/abc123")
        XCTAssertEqual(draft.title, "claude.ai")
        XCTAssertFalse(draft.body.contains("\n"))
    }

    func testDraftSavesThroughStore() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try ShelfStore(paths: ShelfPaths(root: root))

        let draft = try CaptureProcessor.process(text: "Shared from Claude — worth keeping.")
        let note = try store.createNote(body: draft.body, title: draft.title, source: .shareExtension)
        XCTAssertEqual(note.title, "Shared from Claude — worth keeping.")
        XCTAssertEqual(try store.body(of: note.id), draft.body)
    }
}
