import Foundation

/// Per-note reading state. The app persists these in device-local UserDefaults —
/// the portable `index.json` keeps exactly the schema from the brief — but the
/// selection rules live here so they are covered by the headless test suite.
public struct ReadingProgress: Codable, Equatable, Sendable {
    /// A note counts as finished (and stops offering "Continue") past this point.
    public static let finishedThreshold = 0.98
    /// Opening a note records at least this much, so it stops reading as unread.
    public static let openedThreshold = 0.01

    /// Index of the topmost visible markdown block, used to restore scroll.
    public var blockIndex: Int
    /// 0...1 fraction through the note.
    public var progress: Double
    public var lastReadAt: Date

    public init(blockIndex: Int, progress: Double, lastReadAt: Date = Date()) {
        self.blockIndex = max(0, blockIndex)
        self.progress = min(max(progress, 0), 1)
        self.lastReadAt = lastReadAt
    }

    public var isFinished: Bool { progress >= Self.finishedThreshold }

    /// The note for the Bookshelf "Continue" card: the most recently opened one
    /// that has been started but not finished, among the notes still in the library.
    public static func continueCandidate(
        in entries: [UUID: ReadingProgress],
        among noteIds: some Collection<UUID>
    ) -> (noteId: UUID, progress: ReadingProgress)? {
        let live = Set(noteIds)
        return entries
            .filter { live.contains($0.key) && $0.value.progress > 0 && !$0.value.isFinished }
            .max { $0.value.lastReadAt < $1.value.lastReadAt }
            .map { ($0.key, $0.value) }
    }
}
