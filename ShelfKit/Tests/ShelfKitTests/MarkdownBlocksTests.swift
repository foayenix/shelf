import XCTest
@testable import ShelfKit

final class MarkdownBlocksTests: XCTestCase {
    func testSplitsOnBlankLines() {
        let blocks = MarkdownBlocks.split("First para.\n\nSecond para.\n\n\nThird.")
        XCTAssertEqual(blocks, ["First para.", "Second para.", "Third."])
    }

    func testFencedCodeStaysOneBlock() {
        let markdown = """
        Intro line.

        ```swift
        let a = 1

        let b = 2
        ```

        After.
        """
        let blocks = MarkdownBlocks.split(markdown)
        XCTAssertEqual(blocks.count, 3)
        XCTAssertTrue(blocks[1].contains("let a = 1"))
        XCTAssertTrue(blocks[1].contains("let b = 2"),
                      "a blank line inside a fence must not split the block")
    }

    func testTildeFencesAreAlsoRespected() {
        let blocks = MarkdownBlocks.split("~~~\none\n\ntwo\n~~~")
        XCTAssertEqual(blocks.count, 1)
    }

    func testWholeDocumentSurvivesRoundTrip() {
        let joined = MarkdownBlocks.split(sampleMarkdown).joined(separator: "\n")
        for line in sampleMarkdown.split(separator: "\n") where !line.isEmpty {
            XCTAssertTrue(joined.contains(line), "no content may be dropped: \(line)")
        }
    }

    func testEmptyInputYieldsOneBlock() {
        XCTAssertEqual(MarkdownBlocks.split(""), [""])
    }

    func testWhitespaceOnlyLinesSeparateBlocks() {
        XCTAssertEqual(MarkdownBlocks.split("a\n   \nb"), ["a", "b"])
    }
}
