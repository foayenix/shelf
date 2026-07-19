import Foundation

public enum WordCount {
    /// Words are whitespace/newline-separated runs of non-whitespace.
    public static func count(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    /// Reading-time estimate at 200 wpm, never below one minute for non-empty text.
    public static func readingMinutes(wordCount: Int) -> Int {
        guard wordCount > 0 else { return 0 }
        return max(1, Int((Double(wordCount) / 200.0).rounded()))
    }
}
