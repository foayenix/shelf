import XCTest
@testable import ShelfKit

final class TitleDetectorTests: XCTestCase {

    func testFirstHeadingWins() {
        XCTAssertEqual(TitleDetector.title(for: "# The Title\n\nBody text here."), "The Title")
        XCTAssertEqual(TitleDetector.title(for: "intro line\n\n## Deep Heading\ntext"), "Deep Heading")
    }

    func testHeadingMarkdownIsStripped() {
        XCTAssertEqual(TitleDetector.title(for: "### **Bold** `code` title"), "Bold code title")
    }

    func testFirstEightWordsWhenNoHeading() {
        let body = "one two three four five six seven eight nine ten"
        XCTAssertEqual(TitleDetector.title(for: body), "one two three four five six seven eight")
    }

    func testShortBodyUsesAllWords() {
        XCTAssertEqual(TitleDetector.title(for: "just three words"), "just three words")
    }

    func testSkipsBlankLinesAndListMarkers() {
        XCTAssertEqual(TitleDetector.title(for: "\n\n- first item in a list\nmore"), "first item in a list")
        XCTAssertEqual(TitleDetector.title(for: "> quoted opening line"), "quoted opening line")
        XCTAssertEqual(TitleDetector.title(for: "1. ordered item"), "ordered item")
    }

    func testEmptyBodyFallsBack() {
        XCTAssertEqual(TitleDetector.title(for: ""), "Untitled")
        XCTAssertEqual(TitleDetector.title(for: "   \n  "), "Untitled")
    }

    func testBareHashLineIsNotATitle() {
        XCTAssertEqual(TitleDetector.title(for: "#\nreal first line"), "real first line")
    }
}
