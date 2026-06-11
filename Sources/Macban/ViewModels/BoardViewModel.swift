import Foundation
import Observation
import MacbanCore

/// The in-memory, main-actor working copy of an open board. The UI reads and
/// mutates this for instant feedback; every mutation schedules a debounced,
/// atomic write of the affected column file(s) through the `ProjectStore` actor.
@MainActor
@Observable
final class BoardViewModel {
    let store: ProjectStore
    let projectURL: URL
    let boardRef: BoardRef
    private(set) var config: ProjectConfig
    private(set) var board: Board
    private(set) var cardsByColumn: [String: [Card]]

    /// Identifies the card currently open in the detail editor.
    var editTarget: EditTarget?

    /// Called when the project display name changes so recents can stay in sync.
    var onProjectNameChanged: ((String) -> Void)?

    struct EditTarget: Identifiable, Equatable {
        let columnId: String
        let cardId: UUID
        var id: UUID { cardId }
    }

    @ObservationIgnored private let debouncer = Debouncer()
    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var pendingColumnSaves: Set<String> = []
    @ObservationIgnored private var lastMoveKey: String?
    @ObservationIgnored private var lastMoveTime: CFAbsoluteTime = 0

    private init(
        store: ProjectStore,
        url: URL,
        config: ProjectConfig,
        board: Board,
        ref: BoardRef,
        cards: [String: [Card]]
    ) {
        self.store = store
        self.projectURL = url
        self.config = config
        self.board = board
        self.boardRef = ref
        self.cardsByColumn = cards
    }

    /// Loads a project from disk and returns a ready-to-display view model.
    static func load(url: URL) async throws -> BoardViewModel {
        let store = ProjectStore(root: url)
        let config = try await store.loadConfig()
        guard let ref = config.activeBoard else { throw ProjectStoreError.noBoards }
        let board = try await store.loadBoard(ref)
        let cards = try await store.loadAllColumns(board: board, ref: ref)
        let viewModel = BoardViewModel(
            store: store,
            url: url,
            config: config,
            board: board,
            ref: ref,
            cards: cards
        )
        viewModel.startWatching()
        return viewModel
    }

    // MARK: Derived views

    var backlogColumn: Column? {
        board.columns.first { $0.kind == .backlog }
    }

    var flowColumns: [Column] {
        board.columns.filter { $0.kind == .flow }.sorted { $0.order < $1.order }
    }

    func cards(for columnId: String) -> [Card] {
        cardsByColumn[columnId] ?? []
    }

    // MARK: Mutations

    func addCard(title: String, to columnId: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var cards = cardsByColumn[columnId] ?? []
        cards.append(Card(title: trimmed, order: cards.count))
        cardsByColumn[columnId] = cards
        scheduleSave(columnId)
    }

    /// Looks up a card by id within a column (used by the detail editor).
    func card(_ cardId: UUID, in columnId: String) -> Card? {
        cardsByColumn[columnId]?.first { $0.id == cardId }
    }

    /// Replaces an entire card (all fields) and persists the change.
    func update(_ card: Card, in columnId: String) {
        guard var cards = cardsByColumn[columnId],
              let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        var updated = card
        updated.updatedAt = Date()
        cards[index] = updated
        cardsByColumn[columnId] = cards
        scheduleSave(columnId)
    }

    func rename(_ card: Card, in columnId: String, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              var cards = cardsByColumn[columnId],
              let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index].title = trimmed
        cards[index].updatedAt = Date()
        cardsByColumn[columnId] = cards
        scheduleSave(columnId)
    }

    func delete(_ card: Card, from columnId: String) {
        guard var cards = cardsByColumn[columnId] else { return }
        cards.removeAll { $0.id == card.id }
        cardsByColumn[columnId] = cards
        scheduleSave(columnId)
    }

    /// Moves a card within or across columns. When `beforeCardId` is given the card
    /// is inserted ahead of it; otherwise it is appended to the destination.
    ///
    /// Cross-column moves apply both column updates in a single state write so SwiftUI
    /// only invalidates once. No-op moves are ignored.
    func move(cardId: UUID, from source: String, to destination: String, before beforeCardId: UUID?) {
        let moveKey = "\(cardId)|\(source)|\(destination)|\(beforeCardId?.uuidString ?? "end")"
        let now = CFAbsoluteTimeGetCurrent()
        if moveKey == lastMoveKey, now - lastMoveTime < 0.15 { return }
        lastMoveKey = moveKey
        lastMoveTime = now

        guard var sourceCards = cardsByColumn[source],
              let sourceIndex = sourceCards.firstIndex(where: { $0.id == cardId }) else { return }

        var destinationCards = source == destination
            ? sourceCards
            : (cardsByColumn[destination] ?? [])

        let insertIndex = beforeCardId
            .flatMap { id in destinationCards.firstIndex { $0.id == id } }
            ?? destinationCards.count

        // Already at the intended position — skip work to avoid a needless relayout.
        if source == destination,
           sourceIndex == insertIndex || sourceIndex + 1 == insertIndex {
            return
        }
        var card = sourceCards.remove(at: sourceIndex)
        card.updatedAt = Date()

        let adjustedInsertIndex: Int
        if source == destination, sourceIndex < insertIndex {
            adjustedInsertIndex = insertIndex - 1
        } else {
            adjustedInsertIndex = insertIndex
        }
        destinationCards.insert(card, at: adjustedInsertIndex)

        var updated = cardsByColumn
        if source == destination {
            updated[source] = destinationCards
            cardsByColumn = updated
            deferColumnSave(source)
        } else {
            updated[source] = sourceCards
            updated[destination] = destinationCards
            cardsByColumn = updated
            deferColumnSave(source, destination)
        }
    }

    /// Schedules disk writes on the next run-loop turn so drop handlers return
    /// immediately after the in-memory move.
    private func deferColumnSave(_ columnIds: String...) {
        let ids = columnIds
        Task { scheduleSave(ids) }
    }

    // MARK: Project & board settings

    /// Renames the project (the on-disk folder name is left untouched).
    func renameProject(to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != config.name else { return }
        config.name = trimmed
        persistConfig()
        onProjectNameChanged?(trimmed)
    }

    /// Renames the active board title shown in the toolbar.
    func renameBoard(to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != board.name else { return }
        board.name = trimmed
        if let index = config.boards.firstIndex(where: { $0.id == boardRef.id }) {
            config.boards[index].name = trimmed
            persistConfig()
        }
        persistBoard()
    }

    func addColumn(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let id = uniqueColumnId(from: trimmed)
        let order = (board.columns.map(\.order).max() ?? -1) + 1
        board.columns.append(Column(id: id, title: trimmed, kind: .flow, order: order))
        cardsByColumn[id] = []
        persistBoard()
        let store = store
        let ref = boardRef
        Task { try? await store.saveColumn(columnId: id, cards: [], in: ref) }
    }

    func renameColumn(_ column: Column, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = board.columns.firstIndex(where: { $0.id == column.id }) else { return }
        board.columns[index].title = trimmed
        persistBoard()
    }

    /// Removes a flow column. Any cards it holds are moved into the backlog so nothing
    /// is lost. The backlog column itself cannot be deleted.
    func deleteColumn(_ column: Column) {
        guard column.kind != .backlog,
              board.columns.contains(where: { $0.id == column.id }) else { return }

        let orphaned = cardsByColumn[column.id] ?? []
        if let backlogId = backlogColumn?.id, !orphaned.isEmpty {
            var backlogCards = cardsByColumn[backlogId] ?? []
            backlogCards.append(contentsOf: orphaned)
            cardsByColumn[backlogId] = backlogCards
            scheduleSave(backlogId)
        }
        cardsByColumn[column.id] = nil
        board.columns.removeAll { $0.id == column.id }
        renumberColumns()
        persistBoard()

        let url = store.layout.columnFile(columnId: column.id, in: boardRef)
        Task.detached { try? FileManager.default.removeItem(at: url) }
    }

    /// Reorders the flow columns (backlog always stays first).
    func reorderFlowColumns(fromOffsets source: IndexSet, toOffset destination: Int) {
        var flows = flowColumns
        flows.move(fromOffsets: source, toOffset: destination)
        var columns: [Column] = []
        if let backlog = backlogColumn { columns.append(backlog) }
        columns.append(contentsOf: flows)
        board.columns = columns
        renumberColumns()
        persistBoard()
    }

    private func renumberColumns() {
        board.columns.sort { lhs, rhs in
            if lhs.kind == .backlog { return true }
            if rhs.kind == .backlog { return false }
            return lhs.order < rhs.order
        }
        for index in board.columns.indices {
            board.columns[index].order = index
        }
    }

    private func uniqueColumnId(from title: String) -> String {
        let base = title.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let slug = base.isEmpty ? "column" : base
        var candidate = slug
        var suffix = 2
        let existing = Set(board.columns.map(\.id))
        while existing.contains(candidate) {
            candidate = "\(slug)-\(suffix)"
            suffix += 1
        }
        return candidate
    }

    private func persistConfig() {
        let config = config
        let store = store
        Task { try? await store.saveConfig(config) }
    }

    private func persistBoard() {
        let board = board
        let store = store
        let ref = boardRef
        watcher?.mute(for: 1.0)
        Task { try? await store.saveBoard(board, ref: ref) }
    }

    // MARK: Persistence

    private func scheduleSave(_ columnIds: String...) {
        scheduleSave(columnIds)
    }

    private func scheduleSave(_ columnIds: [String]) {
        guard !columnIds.isEmpty else { return }

        pendingColumnSaves.formUnion(columnIds)
        watcher?.mute(for: 1.0)
        let ref = boardRef
        let store = store

        debouncer.schedule("persist") {
            let snapshots = await MainActor.run {
                let ids = self.pendingColumnSaves.sorted()
                self.pendingColumnSaves.removeAll()
                return ids.map { ($0, self.cardsByColumn[$0] ?? []) }
            }
            for (columnId, cards) in snapshots {
                try? await store.saveColumn(columnId: columnId, cards: cards, in: ref)
            }
        }
    }

    // MARK: External sync

    private func startWatching() {
        let directory = store.layout.columnsDirectory(for: boardRef)
        let watcher = FileWatcher(url: directory) { [weak self] in
            Task { @MainActor in
                await self?.reloadFromDisk()
            }
        }
        self.watcher = watcher
        watcher.start()
    }

    private func reloadFromDisk() async {
        guard let board = try? await store.loadBoard(boardRef),
              let cards = try? await store.loadAllColumns(board: board, ref: boardRef) else {
            return
        }
        self.board = board
        self.cardsByColumn = cards
    }
}
