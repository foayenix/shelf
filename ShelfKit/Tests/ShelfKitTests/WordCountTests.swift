import XCTest
@testable import ShelfKit

final class WordCountTests: XCTestCase {

    func testCountsWhitespaceSeparatedWords() {
        XCTAssertEqual(WordCount.count("one two three"), 3)
        XCTAssertEqual(WordCount.count("  spaced\t\tout\n\nwords  "), 3)
        XCTAssertEqual(WordCount.count(""), 0)
        XCTAssertEqual(WordCount.count("   \n "), 0)
    }

    func testMarkdownTokensCountAsWords() {
        // Deliberate: word count is over the raw markdown, exactly as stored.
        XCTAssertEqual(WordCount.count("# Title\n\n**bold** text"), 4)
    }

    func testReadingMinutesAt200Wpm() {
        XCTAssertEqual(WordCount.readingMinutes(wordCount: 0), 0)
        XCTAssertEqual(WordCount.readingMinutes(wordCount: 1), 1, "never zero for non-empty text")
        XCTAssertEqual(WordCount.readingMinutes(wordCount: 199), 1)
        XCTAssertEqual(WordCount.readingMinutes(wordCount: 400), 2)
        XCTAssertEqual(WordCount.readingMinutes(wordCount: 1000), 5)
    }
}
