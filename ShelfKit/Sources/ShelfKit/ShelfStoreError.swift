import Foundation

public enum ShelfStoreError: Error, Equatable {
    case noteNotFound(UUID)
    case collectionNotFound(UUID)
    case emptyCapture
}
