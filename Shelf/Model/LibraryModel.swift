import Foundation
import Observation
import ShelfKit

/// UI-facing state over ShelfKit's `ShelfStore`. All mutations go through here so
/// views re-render from one refreshed snapshot.
@Observable
@MainActor
final class LibraryModel {
    let store: ShelfStore

    private(set) var notes: [Note] = []
    private(set) var collections: [NoteCollection] = []
    /// First body line per note, for list previews. Filled lazily.
    private var previews: [UUID: String] = [:]

    init(store: ShelfStore) {
        self.store = store
        refresh()
    }

    /// Phase 2 store lives in the app documents directory per the brief's file
    /// layout; Phase 3 moves the root to the App Group container.
    static func makeDefault() -> LibraryModel {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            return LibraryModel(store: try ShelfStore(paths: ShelfPaths(root: documents)))
        } catch {
            // Last resort so the app still launches; nothing persists past the session.
            let fallback = FileManager.default.temporaryDirectory
                .appendingPathComponent("ShelfFallback", isDirectory: true)
            return LibraryModel(store: try! ShelfStore(paths: ShelfPaths(root: fallback)))
        }
    }

    func refresh() {
        notes = store.index.notes
        collections = store.collections
    }

    func reloadFromDisk() {
        try? store.reloadFromDisk()
        previews.removeAll()
        refresh()
    }

    // MARK: - Reading

    func notes(in collectionId: UUID?) -> [Note] {
        store.notes(in: collectionId)
    }

    func note(id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func collection(id: UUID?) -> NoteCollection? {
        collections.first { $0.id == id }
    }

    func collectionName(id: UUID?) -> String {
        id.flatMap { collection(id: $0)?.name } ?? "Inbox"
    }

    func body(of noteId: UUID) -> String {
        (try? store.body(of: noteId)) ?? ""
    }

    func preview(of noteId: UUID) -> String {
        if let cached = previews[noteId] { return cached }
        let body = body(of: noteId)
        let line = body
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && !$0.hasPrefix("#") } ?? ""
        let cleaned = line
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
        previews[noteId] = cleaned
        return cleaned
    }

    func wordCount(in collectionId: UUID?) -> Int {
        notes(in: collectionId).reduce(0) { $0 + $1.wordCount }
    }

    var totalWordCount: Int { notes.reduce(0) { $0 + $1.wordCount } }

    // MARK: - Mutations

    @discardableResult
    func saveCapture(_ draft: CaptureDraft, title: String, collectionId: UUID?) throws -> Note {
        let note = try store.createNote(
            body: draft.body,
            title: title,
            collectionId: collectionId,
            source: .paste
        )
        previews.removeValue(forKey: note.id)
        refresh()
        return note
    }

    func deleteNote(_ id: UUID) {
        try? store.deleteNote(id)
        previews.removeValue(forKey: id)
        refresh()
    }

    func moveNote(_ id: UUID, to collectionId: UUID?) {
        try? store.moveNote(id, to: collectionId)
        refresh()
    }

    func renameNote(_ id: UUID, to title: String) {
        try? store.updateTitle(title, for: id)
        refresh()
    }

    func setFavourite(_ favourite: Bool, for id: UUID) {
        try? store.setFavourite(favourite, for: id)
        refresh()
    }

    @discardableResult
    func createCollection(named name: String) -> NoteCollection? {
        let collection = try? store.createCollection(name: name)
        refresh()
        return collection
    }

    func deleteCollection(_ id: UUID) {
        try? store.deleteCollection(id)
        refresh()
    }
}
