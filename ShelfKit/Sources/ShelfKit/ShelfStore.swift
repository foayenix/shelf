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
        try mutateIndex { $0.notes.append(note) }
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
        if let collectionId {
            guard index.collections.contains(where: { $0.id == collectionId }) else {
                throw ShelfStoreError.collectionNotFound(collectionId)
            }
        }
        return try updateNote(id) { $0.collectionId = collectionId }
    }

    @discardableResult
    public func setFavourite(_ favourite: Bool, for id: UUID) throws -> Note {
        try updateNote(id) { $0.favourite = favourite }
    }

    public func deleteNote(_ id: UUID) throws {
        _ = try note(id: id)
        try? FileManager.default.removeItem(at: paths.noteFile(for: id))
        try mutateIndex { $0.notes.removeAll { $0.id == id } }
    }

    // MARK: - Collections

    /// Stored collections in shelf order. The Inbox is virtual and not included.
    public var collections: [NoteCollection] {
        index.collections.sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    public func createCollection(name: String, emoji: String? = nil) throws -> NoteCollection {
        let next = (index.collections.map(\.sortOrder).max() ?? -1) + 1
        let collection = NoteCollection(name: name, emoji: emoji, sortOrder: next)
        try mutateIndex { $0.collections.append(collection) }
        return collection
    }

    @discardableResult
    public func renameCollection(_ id: UUID, to name: String) throws -> NoteCollection {
        guard let i = index.collections.firstIndex(where: { $0.id == id }) else {
            throw ShelfStoreError.collectionNotFound(id)
        }
        try mutateIndex { $0.collections[i].name = name }
        return index.collections[i]
    }

    /// Deletes a collection; its notes fall back to the Inbox, never deleted with it.
    public func deleteCollection(_ id: UUID) throws {
        guard index.collections.contains(where: { $0.id == id }) else {
            throw ShelfStoreError.collectionNotFound(id)
        }
        try mutateIndex { index in
            index.collections.removeAll { $0.id == id }
            for i in index.notes.indices where index.notes[i].collectionId == id {
                index.notes[i].collectionId = nil
            }
        }
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

    /// The `.md` files are the source of truth: a missing or corrupt index is
    /// rebuilt by scanning `notes/`, re-detecting titles and word counts. Rebuilt
    /// notes land in the Inbox with source `.import`.
    @discardableResult
    public func rebuildIndex() throws -> ShelfIndex {
        var rebuilt = ShelfIndex()
        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(at: paths.notesDirectory, includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]))
            ?? []
        for file in files where file.pathExtension == "md" {
            guard let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
                  let body = try? String(contentsOf: file, encoding: .utf8)
            else { continue }
            let values = try? file.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let created = values?.creationDate ?? values?.contentModificationDate ?? .indexPrecision
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
        let fm = FileManager.default
        let known = Set(index.notes.map(\.id))
        let files = (try? fm.contentsOfDirectory(
            at: paths.notesDirectory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]
        )) ?? []

        var adopted: [Note] = []
        for file in files where file.pathExtension == "md" {
            guard let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
                  !known.contains(id),
                  let body = try? String(contentsOf: file, encoding: .utf8)
            else { continue }
            let values = try? file.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let created = values?.creationDate ?? values?.contentModificationDate ?? .indexPrecision
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
            let newNotes = adopted
            try mutateIndex { index in
                let currentIds = Set(index.notes.map(\.id))
                index.notes.append(contentsOf: newNotes.filter { !currentIds.contains($0.id) })
            }
        }
        return adopted
    }

    // MARK: - Private

    private func updateNote(_ id: UUID, _ change: (inout Note) -> Void) throws -> Note {
        var updated: Note?
        try mutateIndex { index in
            guard let i = index.notes.firstIndex(where: { $0.id == id }) else { return }
            change(&index.notes[i])
            index.notes[i].updatedAt = max(.indexPrecision, index.notes[i].updatedAt)
            updated = index.notes[i]
        }
        guard let updated else { throw ShelfStoreError.noteNotFound(id) }
        return updated
    }

    /// Read-modify-write of index.json under file coordination, so concurrent
    /// writes from the app and the extension merge instead of clobbering.
    private func mutateIndex(_ mutate: (inout ShelfIndex) throws -> Void) throws {
        try coordinateIndex(writing: true) { url in
            var current = (try? Self.readIndex(at: url)) ?? index
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

    private func loadOrRebuildIndex() throws -> ShelfIndex {
        var loaded: ShelfIndex?
        try coordinateIndex(writing: false) { url in
            loaded = try? Self.readIndex(at: url)
        }
        if let loaded { return loaded }
        return try rebuildIndex()
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
