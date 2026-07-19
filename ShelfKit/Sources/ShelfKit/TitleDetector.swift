import Foundation

public enum TitleDetector {
    /// Default title for a captured body: the first markdown heading if there is one,
    /// otherwise the first 8 words of the first non-empty line.
    public static func title(for body: String) -> String {
        let lines = body.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#") else { continue }
            let heading = trimmed
                .drop(while: { $0 == "#" })
                .trimmingCharacters(in: .whitespaces)
            if !heading.isEmpty { return stripInlineMarkdown(heading) }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let cleaned = stripInlineMarkdown(stripListMarker(stripHeadingMarker(trimmed)))
            guard !cleaned.isEmpty else { continue }
            let words = cleaned.split(whereSeparator: { $0.isWhitespace }).prefix(8)
            return words.joined(separator: " ")
        }

        return "Untitled"
    }

    private static func stripHeadingMarker(_ line: String) -> String {
        String(Substring(line).drop(while: { $0 == "#" }).drop(while: { $0 == " " }))
    }

    private static func stripListMarker(_ line: String) -> String {
        var s = Substring(line)
        while let first = s.first, first == ">" || first == "-" || first == "*" {
            s = s.dropFirst().drop(while: { $0 == " " })
        }
        // "1. ordered item" → "ordered item"
        let digits = s.prefix(while: { $0.isNumber })
        if !digits.isEmpty, s.dropFirst(digits.count).first == "." {
            s = s.dropFirst(digits.count + 1).drop(while: { $0 == " " })
        }
        return String(s)
    }

    private static func stripInlineMarkdown(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "**", with: "")
        result = result.replacingOccurrences(of: "__", with: "")
        result = result.replacingOccurrences(of: "`", with: "")
        return result.trimmingCharacters(in: .whitespaces)
    }
}
