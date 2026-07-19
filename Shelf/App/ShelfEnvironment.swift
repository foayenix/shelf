import Foundation
import ShelfKit

/// Where Shelf's data lives. Canonical store is the App Group container so the
/// Share Extension can write directly (brief §5); the documents directory is the
/// fallback when the entitlement is missing (e.g. some CI/simulator setups).
enum ShelfEnvironment {
    static let appGroupId = "group.com.lazylab.shelf"

    /// Shared defaults so the extension sees the last-used shelf.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    static func makeStore() throws -> ShelfStore {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let documentsPaths = ShelfPaths(root: documents)

        guard let groupPaths = ShelfPaths.appGroup(id: appGroupId) else {
            return try ShelfStore(paths: documentsPaths)
        }
        // One-time move of any pre-App-Group data; never clobbers existing notes.
        try? ShelfMigrator.migrate(from: documentsPaths, to: groupPaths)
        return try ShelfStore(paths: groupPaths)
    }
}
