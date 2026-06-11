import Foundation

public enum ProjectStoreError: LocalizedError {
    case notAProject(URL)
    case alreadyExists(URL)
    case noBoards

    public var errorDescription: String? {
        switch self {
        case .notAProject(let url):
            return "The folder \(url.lastPathComponent) is not a macban project (no config.json)."
        case .alreadyExists(let url):
            return "A folder named \(url.lastPathComponent) already exists at this location."
        case .noBoards:
            return "This project has no boards."
        }
    }
}

/// Owns all disk I/O for a project. Running as an `actor` keeps reads and writes
/// off the main thread and serialises access, while the UI keeps its working copy
/// in a `@MainActor` view model for instant interaction.
public actor ProjectStore {
    public nonisolated let layout: ProjectLayout

    public init(root: URL) {
        self.layout = ProjectLayout(root: root)
    }

    // MARK: Creating a project

    /// Creates a brand new project folder named `name` inside `parent`, seeded with
    /// a default board and empty column files. Returns the project root URL.
    @discardableResult
    public static func create(name: String, in parent: URL) throws -> URL {
        let fileManager = FileManager.default
        let safeName = sanitize(name)
        let root = parent.appendingPathComponent(safeName, isDirectory: true)

        guard !fileManager.fileExists(atPath: root.path) else {
            throw ProjectStoreError.alreadyExists(root)
        }

        let layout = ProjectLayout(root: root)
        let boardRef = BoardRef(id: "main", name: "Main", path: "boards/main")
        let columns = Board.defaultColumns()
        let board = Board(id: boardRef.id, name: boardRef.name, columns: columns)
        let config = ProjectConfig(
            name: name,
            boards: [boardRef],
            activeBoardId: boardRef.id
        )

        try fileManager.createDirectory(
            at: layout.columnsDirectory(for: boardRef),
            withIntermediateDirectories: true
        )

        try AtomicWrite.write(JSONCoding.encode(config), to: layout.configURL)
        try AtomicWrite.write(JSONCoding.encode(board), to: layout.boardFile(for: boardRef))
        for column in columns {
            try AtomicWrite.write(
                JSONCoding.encode([Card]()),
                to: layout.columnFile(columnId: column.id, in: boardRef)
            )
        }

        return root
    }

    // MARK: Loading

    public func loadConfig() throws -> ProjectConfig {
        guard ProjectLayout.isProject(at: layout.root) else {
            throw ProjectStoreError.notAProject(layout.root)
        }
        let data = try Data(contentsOf: layout.configURL)
        return try JSONCoding.decode(ProjectConfig.self, from: data)
    }

    public func saveConfig(_ config: ProjectConfig) throws {
        try AtomicWrite.write(JSONCoding.encode(config), to: layout.configURL)
    }

    public func loadBoard(_ ref: BoardRef) throws -> Board {
        let data = try Data(contentsOf: layout.boardFile(for: ref))
        return try JSONCoding.decode(Board.self, from: data)
    }

    public func saveBoard(_ board: Board, ref: BoardRef) throws {
        try AtomicWrite.write(JSONCoding.encode(board), to: layout.boardFile(for: ref))
    }

    public nonisolated func loadColumn(columnId: String, in ref: BoardRef) throws -> [Card] {
        let url = layout.columnFile(columnId: columnId, in: ref)
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let cards = try JSONCoding.decode([Card].self, from: data)
        return cards.sorted { $0.order < $1.order }
    }

    /// Loads every column's cards concurrently. Each column is an independent file,
    /// so parallel reads keep board open snappy even with many columns.
    public func loadAllColumns(board: Board, ref: BoardRef) async throws -> [String: [Card]] {
        try await withThrowingTaskGroup(of: (String, [Card]).self) { group in
            for column in board.columns {
                group.addTask {
                    (column.id, try self.loadColumn(columnId: column.id, in: ref))
                }
            }
            var result: [String: [Card]] = [:]
            for try await (columnId, cards) in group {
                result[columnId] = cards
            }
            return result
        }
    }

    // MARK: Saving

    /// Persists one column's cards, renumbering `order` to match array position.
    public func saveColumn(columnId: String, cards: [Card], in ref: BoardRef) throws {
        let renumbered = cards.enumerated().map { index, card -> Card in
            var copy = card
            copy.order = index
            return copy
        }
        try AtomicWrite.write(
            JSONCoding.encode(renumbered),
            to: layout.columnFile(columnId: columnId, in: ref)
        )
    }

    private static func sanitize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return cleaned.isEmpty ? "Untitled Project" : cleaned
    }
}
