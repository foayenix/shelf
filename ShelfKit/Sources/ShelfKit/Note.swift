import Foundation

/// How a note entered the library.
public enum NoteSource: String, Codable, Sendable {
    case shareExtension
    case paste
    case `import`
}

/// One saved response. The body lives in `notes/{id}.md` exactly as captured;
/// everything else is index metadata.
public struct Note: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    /// User-editable. Defaults to the first heading or first 8 words of the body.
    public var title: String
    /// `nil` means the note sits in the virtual Inbox.
    public var collectionId: UUID?
    public var createdAt: Date
    public var updatedAt: Date
    public var source: NoteSource
    public var favourite: Bool
    public var wordCount: Int

    public init(
        id: UUID = UUID(),
        title: String,
        collectionId: UUID? = nil,
        createdAt: Date = .indexPrecision,
        updatedAt: Date = .indexPrecision,
        source: NoteSource,
        favourite: Bool = false,
        wordCount: Int
    ) {
        self.id = id
        self.title = title
        self.collectionId = collectionId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.source = source
        self.favourite = favourite
        self.wordCount = wordCount
    }

    /// Filename of the body file inside `notes/`.
    public var fileName: String { "\(id.uuidString).md" }
}

extension Date {
    /// Dates in index.json are stored as ISO 8601 with whole-second precision.
    /// Creating them pre-truncated keeps round-trips exactly equal.
    public static var indexPrecision: Date {
        Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down))
    }
}
