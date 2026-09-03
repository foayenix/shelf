import Foundation

/// The only reader/writer of the Shelf directory. Owns `index.json` and the
/// `notes/*.md` files; everything above this type (app UI, share extension) goes
/// through its API.
///
/// Concurrency model: instances are not thread-safe — the app uses one instance on
/// the main actor, the share extension creates its own short-lived instance.
/// Cross-*process* safety (app vs. extension writing at the same time) is handled
/// with `NSFileCoordinator` around index reads/writes, and every mutation is
/// read-modify-write against the file rather than trusting the in-memory copy.
/// For the same reason, every lookup a mutation depends on happens *inside* the
/// mutation block, against the copy just read from disk — never against `index`.
public final class ShelfStore {
    public let paths: ShelfPaths

    /// In-memory copy of the index, refreshed on every mutation and `reloadFromDisk()`.
    public private(set) var index: ShelfIndex

    public init(paths: ShelfPaths) throws {
        self.paths = paths
        try FileManager.default.createDirectory(at: paths.notesDirectory, withIntermediateDirectories: true)
        self.index = ShelfIndex()
        self.index = try loadOrRebuildIndex()
    }

    // MARK: - Notes

    /// Notes in a collection (`nil` = Inbox), newest first.
    public func notes(in collectionId: UUID?) -> [Note] {
        index.notes
            .filter { $0.collectionId == collectionId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func note(id: UUID) throws -> Note {
        guard let note = index.notes.first(where: { $0.id == id }) else {
            throw ShelfStoreError.noteNotFound(id)
        }
        return note
    }

    /// Raw markdown body, exactly as captured.
    public func body(of id: UUID) throws -> String {
        _ = try note(id: id)
        return try String(contentsOf: paths.noteFile(for: id), encoding: .utf8)
    }

    @discardableResult
    public func createNote(
        body: String,
        title: String? = nil,
        collectionId: UUID? = nil,
        source: NoteSource,
        favourite: Bool = false
    ) throws -> Note {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShelfStoreError.emptyCapture
        }
        let resolvedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = Note(
            title: (resolvedTitle?.isEmpty == false ? resolvedTitle! : TitleDetector.title(for: body)),
            collectionId: collectionId,
            source: source,
            favourite: favourite,
            wordCount: WordCount.count(body)
        )
        try write(body: body, to: note.id)
        do {
            try mutateIndex { $0.notes.append(note) }
        } catch {
            // Don't leave a body file behind that no index entry points at.
            try? FileManager.default.removeItem(at: paths.noteFile(for: note.id))
            throw error
        }
        return note
    }

    @discardableResult
    public func updateTitle(_ title: String, for id: UUID) throws -> Note {
        try updateNote(id) { $0.title = title }
    }

    /// Rewrites the `.md` file and recomputes the word count.
    @discardableResult
    public func updateBody(_ body: String, for id: UUID) throws -> Note {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShelfStoreError.emptyCapture
        }
        _ = try note(id: id)
        try write(body: body, to: id)
        return try updateNote(id) { $0.wordCount = WordCount.count(body) }
    }

    /// Moves a note to a collection; `nil` sends it back to the Inbox.
    @discardableResult
    public func moveNote(_ id: UUID, to collectionId: UUID?) throws -> Note {
        var updated: Note?
        var missingCollection = false
        try mutateIndex { index in
            if let collectionId, !index.collections.contains(where: { $0.id == collectionId }) {
                missingCollection = true
                return
            }
            guard let i = index.notes.firstIndex(where: { $0.id == id }) else { return }
            index.notes[i].collectionId = collectionId
            index.notes[i].updatedAt = .indexPrecision
            updated = index.notes[i]
        }
        if missingCollection, let collectionId {
            throw ShelfStoreError.collectionNotFound(collectionId)
        }
        guard let updated else { throw ShelfStoreError.noteNotFound(id) }
        return updated
    }

    @discardableResult
    public func setFavourite(_ favourite: Bool, for id: UUID) throws -> Note {
        try updateNote(id) { $0.favourite = favourite }
    }

    public func deleteNote(_ id: UUID) throws {
        _ = try note(id: id)
        // Index first: an orphaned .md file is adopted back on the next scan, but an
        // index entry with no file behind it is a broken note.
        try mutateIndex { $0.notes.removeAll { $0.id == id } }
        try? FileManager.default.removeItem(at: paths.noteFile(for: id))
    }

    // MARK: - Collections

    /// Stored collections in shelf order. The Inbox is virtual and not included.
    public var collections: [NoteCollection] {
        index.collections.sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    public func createCollection(name: String, emoji: String? = nil) throws -> NoteCollection {
        var created: NoteCollection?
        try mutateIndex { index in
            let next = (index.collections.map(\.sortOrder).max() ?? -1) + 1
            let collection = NoteCollection(name: name, emoji: emoji, sortOrder: next)
            index.collections.append(collection)
            created = collection
        }
        guard let created else { throw ShelfStoreError.indexUnreadable }
        return created
    }

    @discardableResult
    public func renameCollection(_ id: UUID, to name: String) throws -> NoteCollection {
        var updated: NoteCollection?
        try mutateIndex { index in
            guard let i = index.collections.firstIndex(where: { $0.id == id }) else { return }
            index.collections[i].name = name
            updated = index.collections[i]
        }
        guard let updated else { throw ShelfStoreError.collectionNotFound(id) }
        return updated
    }

    /// Deletes a collection; its notes fall back to the Inbox, never deleted with it.
    public func deleteCollection(_ id: UUID) throws {
        var found = false
        try mutateIndex { index in
            guard index.collections.contains(where: { $0.id == id }) else { return }
            found = true
            index.collections.removeAll { $0.id == id }
            for i in index.notes.indices where index.notes[i].collectionId == id {
                index.notes[i].collectionId = nil
            }
        }
        guard found else { throw ShelfStoreError.collectionNotFound(id) }
    }

    public func reorderCollections(_ orderedIds: [UUID]) throws {
        try mutateIndex { index in
            for (position, id) in orderedIds.enumerated() {
                if let i = index.collections.firstIndex(where: { $0.id == id }) {
                    index.collections[i].sortOrder = position
                }
            }
        }
    }

    // MARK: - Index lifecycle

    /// Re-reads index.json — call when another process (the share extension) may
    /// have written, e.g. on foreground or on a darwin notification.
    public func reloadFromDisk() throws {
        index = try loadOrRebuildIndex()
    }

    /// The `.md` files are the source of truth: a missing index is rebuilt by
    /// scanning `notes/`, re-detecting titles and word counts. Rebuilt notes land
    /// in the Inbox with source `.import`.
    ///
    /// This drops collections, favourites and hand-edited titles, so it is only
    /// reached when there is no readable index left to lose — see
    /// `loadOrRebuildIndex()`, which quarantines an unreadable file first.
    @discardableResult
    public func rebuildIndex() throws -> ShelfIndex {
        var rebuilt = ShelfIndex()
        for (id, body, created) in scanNoteFiles() {
            rebuilt.notes.append(Note(
                id: id,
                title: TitleDetector.title(for: body),
                createdAt: created,
                updatedAt: created,
                source: .import,
                wordCount: WordCount.count(body)
            ))
        }
        try writeIndex(rebuilt)
        index = rebuilt
        return rebuilt
    }

    /// Adds index entries for `.md` files that exist on disk but aren't in the
    /// index — e.g. notes pulled down from the iCloud mirror. Unlike
    /// `rebuildIndex()`, existing entries and collections are left untouched.
    /// Adopted notes land in the Inbox with source `.import`.
    @discardableResult
    public func adoptOrphanNotes() throws -> [Note] {
        let known = Set(index.notes.map(\.id))
        var adopted: [Note] = []
        for (id, body, created) in scanNoteFiles() where !known.contains(id) {
            adopted.append(Note(
                id: id,
                title: TitleDetector.title(for: body),
                createdAt: created,
                updatedAt: created,
                source: .import,
                wordCount: WordCount.count(body)
            ))
        }

        if !adopted.isEmpty {
            try mutateIndex { index in
                let currentIds = Set(index.notes.map(\.id))
                index.notes.append(contentsOf: adopted.filter { !currentIds.contains($0.id) })
            }
        }
        return adopted
    }

    // MARK: - Private

    /// Every readable `notes/{uuid}.md`, with its creation date. Foreign files and
    /// non-UUID names are ignored.
    private func scanNoteFiles() -> [(id: UUID, body: String, created: Date)] {
        let keys: [URLResourceKey] = [.creationDateKey, .contentModificationDateKey]
        let files = (try? FileManager.default.contentsOfDirectory(
            at: paths.notesDirectory,
            includingPropertiesForKeys: keys
        )) ?? []

        return files.compactMap { file in
            guard file.pathExtension == "md",
                  let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
                  let body = try? String(contentsOf: file, encoding: .utf8)
            else { return nil }
            let values = try? file.resourceValues(forKeys: Set(keys))
            let created = values?.creationDate ?? values?.contentModificationDate ?? .indexPrecision
            return (id: id, body: body, created: created)
        }
    }

    private func updateNote(_ id: UUID, _ change: (inout Note) -> Void) throws -> Note {
        var updated: Note?
        try mutateIndex { index in
            guard let i = index.notes.firstIndex(where: { $0.id == id }) else { return }
            change(&index.notes[i])
            index.notes[i].updatedAt = .indexPrecision
            updated = index.notes[i]
        }
        guard let updated else { throw ShelfStoreError.noteNotFound(id) }
        return updated
    }

    /// Read-modify-write of index.json under file coordination, so concurrent
    /// writes from the app and the extension merge instead of clobbering.
    ///
    /// A file that exists but won't decode throws rather than being overwritten —
    /// recovery is `loadOrRebuildIndex()`'s job, and it quarantines before it
    /// rebuilds. A file that isn't there yet is a fresh store, so the in-memory
    /// copy is the best base available.
    private func mutateIndex(_ mutate: (inout ShelfIndex) throws -> Void) throws {
        try coordinateIndex(writing: true) { url in
            var current: ShelfIndex
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    current = try Self.readIndex(at: url)
                } catch {
                    throw ShelfStoreError.indexUnreadable
                }
            } else {
                current = index
            }
            try mutate(&current)
            let data = try ShelfIndex.encoder().encode(current)
            try data.write(to: url, options: .atomic)
            index = current
        }
    }

    private func writeIndex(_ newIndex: ShelfIndex) throws {
        try coordinateIndex(writing: true) { url in
            let data = try ShelfIndex.encoder().encode(newIndex)
            try data.write(to: url, options: .atomic)
        }
    }

    /// Loads the index, and only rebuilds when there is nothing readable to keep.
    /// An index written by a newer schema is never rebuilt — that would silently
    /// discard whatever the newer build stored.
    private func loadOrRebuildIndex() throws -> ShelfIndex {
        var loaded: ShelfIndex?
        var existed = false
        try coordinateIndex(writing: false) { url in
            existed = FileManager.default.fileExists(atPath: url.path)
            guard existed else { return }
            loaded = try? Self.readIndex(at: url)
        }

        if let loaded {
            guard loaded.schemaVersion <= ShelfIndex.currentSchemaVersion else {
                throw ShelfStoreError.indexFromNewerVersion(loaded.schemaVersion)
            }
            return loaded
        }
        // Unreadable, not merely absent: keep the bytes so the metadata can be
        // recovered by hand, then fall back to the .md files.
        if existed { try? quarantineIndex() }
        return try rebuildIndex()
    }

    /// Moves an undecodable index aside as `index-corrupt-<timestamp>.json`.
    private func quarantineIndex() throws {
        let stamp = Int(Date().timeIntervalSince1970)
        let destination = paths.shelfDirectory
            .appendingPathComponent("index-corrupt-\(stamp).json")
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: paths.indexFile, to: destination)
    }

    private static func readIndex(at url: URL) throws -> ShelfIndex {
        let data = try Data(contentsOf: url)
        return try ShelfIndex.decoder().decode(ShelfIndex.self, from: data)
    }

    private func write(body: String, to id: UUID) throws {
        try Data(body.utf8).write(to: paths.noteFile(for: id), options: .atomic)
    }

    private func coordinateIndex(writing: Bool, _ work: (URL) throws -> Void) throws {
        #if os(iOS) || os(macOS)
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var workError: Error?
        let accessor: (URL) -> Void = { url in
            do { try work(url) } catch { workError = error }
        }
        if writing {
            coordinator.coordinate(writingItemAt: paths.indexFile, options: .forReplacing, error: &coordinationError, byAccessor: accessor)
        } else {
            coordinator.coordinate(readingItemAt: paths.indexFile, options: [], error: &coordinationError, byAccessor: accessor)
        }
        if let coordinationError { throw coordinationError }
        if let workError { throw workError }
        #else
        // Linux (CI): no NSFileCoordinator; single-process tests don't need it.
        try work(paths.indexFile)
        #endif
    }
}
