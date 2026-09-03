import XCTest
@testable import ShelfKit

final class ReadingProgressTests: XCTestCase {
    private let a = UUID()
    private let b = UUID()
    private let c = UUID()

    func testProgressIsClampedAndBlockIndexIsNonNegative() {
        XCTAssertEqual(ReadingProgress(blockIndex: -4, progress: 1.8).progress, 1)
        XCTAssertEqual(ReadingProgress(blockIndex: -4, progress: 1.8).blockIndex, 0)
        XCTAssertEqual(ReadingProgress(blockIndex: 2, progress: -0.5).progress, 0)
    }

    func testFinishedAtThreshold() {
        XCTAssertTrue(ReadingProgress(blockIndex: 9, progress: 0.99).isFinished)
        XCTAssertFalse(ReadingProgress(blockIndex: 9, progress: 0.5).isFinished)
    }

    func testCandidateIsMostRecentlyReadUnfinishedNote() {
        let now = Date()
        let entries = [
            a: ReadingProgress(blockIndex: 1, progress: 0.3, lastReadAt: now.addingTimeInterval(-60)),
            b: ReadingProgress(blockIndex: 4, progress: 0.6, lastReadAt: now),
        ]
        XCTAssertEqual(ReadingProgress.continueCandidate(in: entries, among: [a, b])?.noteId, b)
    }

    func testFinishedAndUnstartedNotesAreSkipped() {
        let now = Date()
        let entries = [
            a: ReadingProgress(blockIndex: 40, progress: 1, lastReadAt: now),
            b: ReadingProgress(blockIndex: 0, progress: 0, lastReadAt: now),
            c: ReadingProgress(blockIndex: 2, progress: 0.2, lastReadAt: now.addingTimeInterval(-600)),
        ]
        XCTAssertEqual(ReadingProgress.continueCandidate(in: entries, among: [a, b, c])?.noteId, c)
    }

    func testDeletedNotesAreNeverOffered() {
        let entries = [a: ReadingProgress(blockIndex: 1, progress: 0.4)]
        XCTAssertNil(ReadingProgress.continueCandidate(in: entries, among: [b, c]))
    }

    func testNoCandidateWhenNothingStarted() {
        XCTAssertNil(ReadingProgress.continueCandidate(in: [:], among: [a]))
    }
}
