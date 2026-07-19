import Foundation
import Observation

/// Per-note reading state — scroll position, progress, last-opened time. Kept in
/// UserDefaults (device-local) rather than index.json so the portable index stays
/// exactly the schema from the brief.
@Observable
final class ReadingProgressStore {
    struct Entry: Codable, Equatable {
        /// Index of the topmost visible markdown block, used to restore scroll.
        var blockIndex: Int
        /// 0...1 fraction through the note.
        var progress: Double
        var lastReadAt: Date
    }

    private static let key = "shelf_reading_progress"
    private let defaults: UserDefaults
    private(set) var entries: [UUID: Entry]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([UUID: Entry].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
    }

    func entry(for noteId: UUID) -> Entry? { entries[noteId] }

    /// A note is "unread" until it has been opened once.
    func isUnread(_ noteId: UUID) -> Bool { entries[noteId] == nil }

    func record(noteId: UUID, blockIndex: Int, progress: Double) {
        entries[noteId] = Entry(blockIndex: blockIndex, progress: progress.clamped(to: 0...1), lastReadAt: Date())
        persist()
    }

    func forget(noteId: UUID) {
        entries.removeValue(forKey: noteId)
        persist()
    }

    /// The note for the Bookshelf "Continue" card: most recently opened, unfinished.
    func continueCandidate(among notes: [UUID]) -> (noteId: UUID, entry: Entry)? {
        entries
            .filter { notes.contains($0.key) && $0.value.progress < 0.98 && $0.value.progress > 0 }
            .max { $0.value.lastReadAt < $1.value.lastReadAt }
            .map { ($0.key, $0.value) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
