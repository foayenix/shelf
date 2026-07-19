import Foundation

/// One-time move of a shelf to a new root — used when the app switches its
/// canonical store from the documents directory to the App Group container.
public enum ShelfMigrator {
    /// Moves `source`'s Shelf directory to `destination`. No-op when the source
    /// has no shelf, or when the destination already contains notes (never
    /// clobbers real data). A destination with an index but zero notes can only
    /// be a freshly initialised empty store, so it is safe to replace.
    public static func migrate(from source: ShelfPaths, to destination: ShelfPaths) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: source.shelfDirectory.path) else { return }

        let destinationNotes = (try? fm.contentsOfDirectory(atPath: destination.notesDirectory.path)) ?? []
        guard destinationNotes.filter({ $0.hasSuffix(".md") }).isEmpty else { return }

        if fm.fileExists(atPath: destination.shelfDirectory.path) {
            try fm.removeItem(at: destination.shelfDirectory)
        }
        try fm.createDirectory(at: destination.root, withIntermediateDirectories: true)
        try fm.moveItem(at: source.shelfDirectory, to: destination.shelfDirectory)
    }
}
