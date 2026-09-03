import Foundation
import Observation
import ShelfKit

/// UI-facing state over ShelfKit's `ShelfStore`. All mutations go through here so
/// views re-render from one refreshed snapshot.
@Observable
@MainActor
final class LibraryModel {
    /// How the library opened. Anything other than `.ready` is shown to the user
    /// rather than swallowed — a shelf that silently isn't the real one loses notes.
    enum Health: Equatable {
        case ready
        /// Opened, but not in the App Group container the extension writes to.
        case degraded(ShelfEnvironment.Location)
        /// No store at all; the app can be opened but nothing can be saved.
        case unavailable(String)
    }

    private(set) var store: ShelfStore?
    private(set) var health: Health = .ready

    private(set) var notes: [Note] = []
    private(set) var collections: [NoteCollection] = []

    /// Body/preview caches. `@ObservationIgnored` on purpose: they are filled while
    /// views are rendering, and an observed write during a view update re-renders
    /// the view that just triggered it.
    @ObservationIgnored private var previews: [UUID: String] = [:]
    @ObservationIgnored private var bodies: [UUID: String] = [:]
    /// Insertion order for `bodies`, so a long library can't pin every note in memory.
    @ObservationIgnored private var bodyOrder: [UUID] = []
    private static let bodyCacheLimit = 32

    init(store: ShelfStore?, health: Health) {
        self.store = store
        self.health = health
        refresh()
    }

    static func makeDefault() -> LibraryModel {
        do {
            let opened = try ShelfEnvironment.makeStore()
            return LibraryModel(
                store: opened.store,
                health: opened.location == .appGroup ? .ready : .degraded(opened.location)
            )
        } catch {
            return LibraryModel(store: nil, health: .unavailable(Self.describe(error)))
        }
    }

    private static func describe(_ error: Error) -> String {
        switch error as? ShelfStoreError {
        case .indexFromNewerVersion:
            return "This library was written by a newer version of Shelf. Update the app to open it — your notes are untouched."
        case .indexUnreadable:
            return "Shelf couldn't read your library index. Your notes are still on disk."
        default:
            return "Shelf couldn't open your library."
        }
    }

    var canSave: Bool { store != nil }

    func refresh() {
        notes = store?.index.notes ?? []
        collections = store?.collections ?? []
    }

    func reloadFromDisk() {
        try? store?.reloadFromDisk()
        previews.removeAll()
        bodies.removeAll()
        bodyOrder.removeAll()
        refresh()
    }

    // MARK: - Reading

    func notes(in collectionId: UUID?) -> [Note] {
        store?.notes(in: collectionId) ?? []
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

    /// Reads the body off the main actor — note files run to 100k characters and
    /// this is called while lists scroll.
    func body(of noteId: UUID) async -> String {
        if let cached = bodies[noteId] { return cached }
        guard let url = store?.paths.noteFile(for: noteId) else { return "" }
        let text = await Task.detached(priority: .userInitiated) {
            (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        }.value
        cache(body: text, for: noteId)
        return text
    }

    /// First body line, for list previews.
    func preview(of noteId: UUID) async -> String {
        if let cached = previews[noteId] { return cached }
        let cleaned = Self.firstLine(of: await body(of: noteId))
        previews[noteId] = cleaned
        return cleaned
    }

    /// Full-text search across titles and bodies, newest first. Bodies are scanned
    /// in one pass off the main actor and deliberately don't go through the body
    /// cache — a whole-library scan would evict everything the Reader needs.
    func search(_ query: String) async -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let paths = store?.paths else { return [] }

        let candidates = notes
            .filter { !$0.title.localizedCaseInsensitiveContains(trimmed) }
            .map(\.id)
        let files = candidates.map { paths.noteFile(for: $0) }
        let cached = bodies

        let bodyMatches: Set<UUID> = await Task.detached(priority: .userInitiated) {
            var found: Set<UUID> = []
            for (id, file) in zip(candidates, files) {
                if Task.isCancelled { return found }
                let text = cached[id] ?? (try? String(contentsOf: file, encoding: .utf8))
                if text?.localizedCaseInsensitiveContains(trimmed) == true {
                    found.insert(id)
                }
            }
            return found
        }.value

        return notes
            .filter { $0.title.localizedCaseInsensitiveContains(trimmed) || bodyMatches.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private static func firstLine(of body: String) -> String {
        let line = body
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && !$0.hasPrefix("#") } ?? ""
        return line
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
    }

    private func cache(body: String, for noteId: UUID) {
        if bodies[noteId] == nil {
            bodyOrder.append(noteId)
            while bodyOrder.count > Self.bodyCacheLimit {
                bodies.removeValue(forKey: bodyOrder.removeFirst())
            }
        }
        bodies[noteId] = body
    }

    // MARK: - Mutations

    @discardableResult
    func saveCapture(_ draft: CaptureDraft, title: String, collectionId: UUID?) throws -> Note {
        guard let store else { throw ShelfStoreError.indexUnreadable }
        let note = try store.createNote(
            body: draft.body,
            title: title,
            collectionId: collectionId,
            source: .paste
        )
        forget(note.id)
        refresh()
        return note
    }

    func deleteNote(_ id: UUID) {
        try? store?.deleteNote(id)
        forget(id)
        refresh()
    }

    func moveNote(_ id: UUID, to collectionId: UUID?) {
        try? store?.moveNote(id, to: collectionId)
        refresh()
    }

    func renameNote(_ id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? store?.updateTitle(trimmed, for: id)
        refresh()
    }

    func setFavourite(_ favourite: Bool, for id: UUID) {
        try? store?.setFavourite(favourite, for: id)
        refresh()
    }

    private func forget(_ id: UUID) {
        previews.removeValue(forKey: id)
        bodies.removeValue(forKey: id)
        bodyOrder.removeAll { $0 == id }
    }

    // MARK: - Shelves

    @discardableResult
    func createCollection(named name: String) -> NoteCollection? {
        guard let store else { return nil }
        let collection = try? store.createCollection(name: name)
        refresh()
        return collection
    }

    func renameCollection(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? store?.renameCollection(id, to: trimmed)
        refresh()
    }

    /// Deletes the shelf only — its notes fall back to the Inbox.
    func deleteCollection(_ id: UUID) {
        try? store?.deleteCollection(id)
        refresh()
    }

    /// Moves a shelf one place up or down the bookshelf.
    func moveCollection(_ id: UUID, by offset: Int) {
        var order = collections.map(\.id)
        guard let from = order.firstIndex(of: id) else { return }
        let to = from + offset
        guard order.indices.contains(to) else { return }
        order.swapAt(from, to)
        try? store?.reorderCollections(order)
        refresh()
    }

    func canMoveCollection(_ id: UUID, by offset: Int) -> Bool {
        guard let from = collections.firstIndex(where: { $0.id == id }) else { return false }
        return collections.indices.contains(from + offset)
    }
}
