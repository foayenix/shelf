import Foundation

/// A validated capture, ready to hand to `ShelfStore.createNote`.
public struct CaptureDraft: Equatable, Sendable {
    /// Raw markdown, exactly as captured (after truncation, if any).
    public let body: String
    /// Auto-detected title; the UI lets the user edit it before saving.
    public let title: String
    public let wordCount: Int
    /// True when the input exceeded `CaptureProcessor.maxCharacters` — the UI
    /// must warn the user (brief §5).
    public let truncated: Bool
}

public enum CaptureProcessor {
    /// Hard cap from the brief: captures over 100k characters are truncated with a warning.
    public static let maxCharacters = 100_000

    /// Validates and prepares shared/pasted text. Throws `.emptyCapture` for
    /// whitespace-only input.
    public static func process(text: String) throws -> CaptureDraft {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShelfStoreError.emptyCapture
        }
        var body = text
        var truncated = false
        if body.count > maxCharacters {
            body = String(body.prefix(maxCharacters))
            truncated = true
        }
        return CaptureDraft(
            body: body,
            title: TitleDetector.title(for: body),
            wordCount: WordCount.count(body),
            truncated: truncated
        )
    }

    /// A URL shared into the extension becomes a one-line note (brief §5).
    public static func process(url: URL) -> CaptureDraft {
        let body = url.absoluteString
        return CaptureDraft(
            body: body,
            title: url.host ?? body,
            wordCount: 1,
            truncated: false
        )
    }
}
