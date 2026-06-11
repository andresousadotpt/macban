import Foundation

/// The contents of a board's `board.json`: its column layout. Card data is stored
/// separately, one file per column, under `columns/`.
public struct Board: Codable, Sendable, Identifiable, Hashable {
    public var version: Int
    public let id: String
    public var name: String
    public var columns: [Column]

    public init(version: Int = 1, id: String, name: String, columns: [Column]) {
        self.version = version
        self.id = id
        self.name = name
        self.columns = columns.sorted { $0.order < $1.order }
    }

    /// The default column layout for a freshly created board: a backlog plus the
    /// classic To Do / In Progress / Done flow.
    public static func defaultColumns() -> [Column] {
        [
            Column(id: "backlog", title: "Backlog", kind: .backlog, order: 0),
            Column(id: "todo", title: "To Do", kind: .flow, order: 1),
            Column(id: "in-progress", title: "In Progress", kind: .flow, order: 2),
            Column(id: "done", title: "Done", kind: .flow, order: 3)
        ]
    }
}
