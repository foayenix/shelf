import Foundation

/// Splits a markdown document into top-level blocks (separated by blank lines,
/// with fenced code blocks kept intact). Each block renders as its own view so
/// the Reader can remember and restore scroll position by block id — plain
/// SwiftUI on iOS 17 has no offset-based restore for a single tall view.
public enum MarkdownBlocks {
    public static func split(_ markdown: String) -> [String] {
        var blocks: [String] = []
        var current: [Substring] = []
        var inFence = false

        func flush() {
            if !current.isEmpty {
                blocks.append(current.joined(separator: "\n"))
                current = []
            }
        }

        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                current.append(line)
                continue
            }
            if trimmed.isEmpty && !inFence {
                flush()
            } else {
                current.append(line)
            }
        }
        flush()
        return blocks.isEmpty ? [markdown] : blocks
    }
}
