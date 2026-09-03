import Foundation
import Observation
import ShelfKit

/// Per-note reading state — scroll position, progress, last-opened time. Kept in
/// UserDefaults (device-local) rather than index.json so the portable index stays
/// exactly the schema from the brief. The selection rules live in ShelfKit's
/// `ReadingProgress` so they're covered by the headless test suite.
@Observable
final class ReadingProgressStore {
    private let defaults: UserDefaults
    private(set) var entries: [UUID: ReadingProgress]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: ShelfEnvironment.Key.readingProgress),
           let decoded = try? JSONDecoder().decode([UUID: ReadingProgress].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
    }

    func entry(for noteId: UUID) -> ReadingProgress? { entries[noteId] }

    /// A note is "unread" until it has been opened once.
    func isUnread(_ noteId: UUID) -> Bool { entries[noteId] == nil }

    func record(noteId: UUID, blockIndex: Int, progress: Double) {
        entries[noteId] = ReadingProgress(blockIndex: blockIndex, progress: progress)
        persist()
    }

    func forget(noteId: UUID) {
        entries.removeValue(forKey: noteId)
        persist()
    }

    /// The note for the Bookshelf "Continue" card: most recently opened, unfinished.
    func continueCandidate(among notes: [UUID]) -> (noteId: UUID, entry: ReadingProgress)? {
        ReadingProgress.continueCandidate(in: entries, among: notes)
            .map { (noteId: $0.noteId, entry: $0.progress) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: ShelfEnvironment.Key.readingProgress)
        }
    }
}
