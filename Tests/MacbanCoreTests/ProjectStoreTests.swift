import Foundation
import Testing
@testable import MacbanCore

@Suite("ProjectStore")
struct ProjectStoreTests {
    /// Creates a unique temporary directory to act as the parent for test projects.
    private func makeTempParent() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("macban-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Creating a project scaffolds config, board and empty column files")
    func createScaffold() async throws {
        let parent = try makeTempParent()
        defer { try? FileManager.default.removeItem(at: parent) }

        let root = try ProjectStore.create(name: "Demo", in: parent)
        let layout = ProjectLayout(root: root)

        #expect(ProjectLayout.isProject(at: root))
        #expect(FileManager.default.fileExists(atPath: layout.configURL.path))

        let store = ProjectStore(root: root)
        let config = try await store.loadConfig()
        #expect(config.name == "Demo")
        #expect(config.boards.count == 1)

        let ref = try #require(config.activeBoard)
        let board = try await store.loadBoard(ref)
        #expect(board.columns.map(\.id) == ["backlog", "todo", "in-progress", "done"])
        #expect(board.columns.first?.kind == .backlog)

        for column in board.columns {
            let cards = try await store.loadColumn(columnId: column.id, in: ref)
            #expect(cards.isEmpty)
        }
    }

    @Test("Refusing to create a project where the folder already exists")
    func createDuplicateThrows() throws {
        let parent = try makeTempParent()
        defer { try? FileManager.default.removeItem(at: parent) }

        _ = try ProjectStore.create(name: "Dup", in: parent)
        #expect(throws: ProjectStoreError.self) {
            _ = try ProjectStore.create(name: "Dup", in: parent)
        }
    }

    @Test("Opening a non-project folder throws")
    func loadNonProjectThrows() async throws {
        let parent = try makeTempParent()
        defer { try? FileManager.default.removeItem(at: parent) }

        let store = ProjectStore(root: parent)
        await #expect(throws: ProjectStoreError.self) {
            _ = try await store.loadConfig()
        }
    }

    @Test("Saving a column renumbers order and round-trips through disk")
    func saveColumnRoundTrip() async throws {
        let parent = try makeTempParent()
        defer { try? FileManager.default.removeItem(at: parent) }

        let root = try ProjectStore.create(name: "Cards", in: parent)
        let store = ProjectStore(root: root)
        let ref = try #require(try await store.loadConfig().activeBoard)

        let cards = [
            Card(title: "First", order: 99),
            Card(title: "Second", order: 5),
            Card(title: "Third", order: 0)
        ]
        try await store.saveColumn(columnId: "todo", cards: cards, in: ref)

        let loaded = try await store.loadColumn(columnId: "todo", in: ref)
        #expect(loaded.map(\.title) == ["First", "Second", "Third"])
        #expect(loaded.map(\.order) == [0, 1, 2])
    }

    @Test("Loading all columns concurrently returns every column")
    func loadAllColumns() async throws {
        let parent = try makeTempParent()
        defer { try? FileManager.default.removeItem(at: parent) }

        let root = try ProjectStore.create(name: "All", in: parent)
        let store = ProjectStore(root: root)
        let config = try await store.loadConfig()
        let ref = try #require(config.activeBoard)
        let board = try await store.loadBoard(ref)

        try await store.saveColumn(columnId: "todo", cards: [Card(title: "A")], in: ref)
        try await store.saveColumn(columnId: "done", cards: [Card(title: "B"), Card(title: "C")], in: ref)

        let all = try await store.loadAllColumns(board: board, ref: ref)
        #expect(all.count == board.columns.count)
        #expect(all["todo"]?.count == 1)
        #expect(all["done"]?.count == 2)
        #expect(all["backlog"]?.isEmpty == true)
    }
}
