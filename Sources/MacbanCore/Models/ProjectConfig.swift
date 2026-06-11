import Foundation

/// A reference to a board within a project, as stored in `config.json`. The `path`
/// is relative to the project root so a project folder stays portable across machines.
public struct BoardRef: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public var name: String
    public var path: String

    public init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

/// The contents of a project's `config.json`: identity, metadata and the board registry.
public struct ProjectConfig: Codable, Sendable, Identifiable, Hashable {
    public var version: Int
    public let id: UUID
    public var name: String
    public let createdAt: Date
    public var boards: [BoardRef]
    public var activeBoardId: String

    public init(
        version: Int = 1,
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        boards: [BoardRef],
        activeBoardId: String
    ) {
        self.version = version
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.boards = boards
        self.activeBoardId = activeBoardId
    }

    public var activeBoard: BoardRef? {
        boards.first { $0.id == activeBoardId } ?? boards.first
    }
}
