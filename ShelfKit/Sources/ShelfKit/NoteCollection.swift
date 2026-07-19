import Foundation

/// A shelf. The Inbox is not a stored collection — notes with `collectionId == nil`
/// belong to it, so it can never be renamed or deleted.
public struct NoteCollection: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var emoji: String?
    public var sortOrder: Int

    public init(id: UUID = UUID(), name: String, emoji: String? = nil, sortOrder: Int) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
    }
}
