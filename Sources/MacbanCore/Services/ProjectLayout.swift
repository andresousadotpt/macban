import Foundation

/// Resolves the on-disk paths for a project folder. Centralising path math keeps
/// the layout in one place and makes the structure easy to change later.
///
/// ```
/// MyProject/
/// ├── config.json
/// └── boards/
///     └── main/
///         ├── board.json
///         └── columns/
///             ├── backlog.json
///             └── ...
/// ```
public struct ProjectLayout: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public static let configFileName = "config.json"
    public static let boardFileName = "board.json"

    public var configURL: URL {
        root.appendingPathComponent(Self.configFileName)
    }

    public var boardsDirectory: URL {
        root.appendingPathComponent("boards", isDirectory: true)
    }

    public func boardDirectory(for ref: BoardRef) -> URL {
        root.appendingPathComponent(ref.path, isDirectory: true)
    }

    public func boardFile(for ref: BoardRef) -> URL {
        boardDirectory(for: ref).appendingPathComponent(Self.boardFileName)
    }

    public func columnsDirectory(for ref: BoardRef) -> URL {
        boardDirectory(for: ref).appendingPathComponent("columns", isDirectory: true)
    }

    public func columnFile(columnId: String, in ref: BoardRef) -> URL {
        columnsDirectory(for: ref).appendingPathComponent("\(columnId).json")
    }

    /// A folder is a valid macban project if it contains a `config.json` at its root.
    public static func isProject(at url: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: url.appendingPathComponent(configFileName).path
        )
    }
}
