import Foundation

/// Distinguishes the always-present backlog from ordinary flow columns.
public enum ColumnKind: String, Codable, Sendable {
    case backlog
    case flow
}

/// A column definition stored in `board.json`. The cards themselves live in a
/// separate per-column file so that moving a card only rewrites one or two files.
public struct Column: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public var title: String
    public var kind: ColumnKind
    public var order: Int

    public init(id: String, title: String, kind: ColumnKind, order: Int) {
        self.id = id
        self.title = title
        self.kind = kind
        self.order = order
    }
}
