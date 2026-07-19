import Foundation

/// Resolves the on-disk layout under an injectable root, so tests can point at a
/// temporary directory and the app at the App Group container:
///
///     <root>/Shelf/index.json
///     <root>/Shelf/notes/{uuid}.md
public struct ShelfPaths: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public var shelfDirectory: URL { root.appendingPathComponent("Shelf", isDirectory: true) }
    public var notesDirectory: URL { shelfDirectory.appendingPathComponent("notes", isDirectory: true) }
    public var indexFile: URL { shelfDirectory.appendingPathComponent("index.json") }

    public func noteFile(for id: UUID) -> URL {
        notesDirectory.appendingPathComponent("\(id.uuidString).md")
    }

    #if os(iOS) || os(macOS)
    /// The shared container both the app and the Share Extension write to.
    public static func appGroup(id: String) -> ShelfPaths? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            return nil
        }
        return ShelfPaths(root: url)
    }
    #endif
}
