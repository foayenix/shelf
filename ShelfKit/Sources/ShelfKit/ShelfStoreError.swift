import Foundation

public enum ShelfStoreError: Error, Equatable {
    case noteNotFound(UUID)
    case collectionNotFound(UUID)
    case emptyCapture
    /// `index.json` exists but can't be decoded. Thrown instead of overwriting it,
    /// so a mid-session mutation never flattens metadata another process wrote.
    case indexUnreadable
    /// The index was written by a newer build than this one. Rebuilding would drop
    /// whatever that build added, so the store refuses to open instead.
    case indexFromNewerVersion(Int)
}
