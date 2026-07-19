import Foundation

/// The whole of `index.json`. Kept deliberately small — the `.md` files are the
/// source of truth and the index can always be rebuilt from them.
public struct ShelfIndex: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var notes: [Note]
    public var collections: [NoteCollection]

    public init(
        schemaVersion: Int = ShelfIndex.currentSchemaVersion,
        notes: [Note] = [],
        collections: [NoteCollection] = []
    ) {
        self.schemaVersion = schemaVersion
        self.notes = notes
        self.collections = collections
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
