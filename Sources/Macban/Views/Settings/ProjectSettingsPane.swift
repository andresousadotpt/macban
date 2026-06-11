import SwiftUI
import AppKit
import MacbanCore

/// Project-scoped settings: name, board title, location, and columns.
struct ProjectSettingsPane: View {
    @Bindable var board: BoardViewModel
    @Environment(AppViewModel.self) private var app

    @State private var projectName: String
    @State private var boardName: String
    @State private var newColumnTitle = ""

    init(board: BoardViewModel) {
        self.board = board
        _projectName = State(initialValue: board.config.name)
        _boardName = State(initialValue: board.board.name)
    }

    var body: some View {
        Form {
            generalSection
            columnsSection
        }
        .formStyle(.grouped)
        .navigationTitle("Project")
        .onDisappear(perform: commitNames)
    }

    private var generalSection: some View {
        Section {
            LabeledContent("Project Name") {
                TextField("Project name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
                    .onSubmit(commitNames)
            }

            LabeledContent("Board Title") {
                TextField("Board title", text: $boardName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
                    .onSubmit(commitNames)
            }

            LabeledContent("Location") {
                HStack(spacing: 8) {
                    Text(board.projectURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([board.projectURL])
                    }
                    .controlSize(.small)
                }
            }
        } header: {
            Text("General")
        } footer: {
            Text("The project name is shown in the toolbar and recents. The folder name on disk is not changed when you rename the project.")
        }
    }

    private var columnsSection: some View {
        Section {
            if let backlog = board.backlogColumn {
                HStack {
                    Image(systemName: "tray.full")
                        .foregroundStyle(.secondary)
                    Text(backlog.title)
                    Spacer()
                    Text("Backlog")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            ForEach(board.flowColumns) { column in
                ColumnSettingRow(board: board, column: column)
            }
            .onMove { source, destination in
                board.reorderFlowColumns(fromOffsets: source, toOffset: destination)
            }

            HStack(spacing: 8) {
                TextField("New column", text: $newColumnTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addColumn)
                Button("Add", action: addColumn)
                    .disabled(newColumnTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("Columns")
        } footer: {
            Text("Drag to reorder flow columns. Deleting a column moves its cards to the backlog.")
        }
    }

    private func commitNames() {
        board.renameProject(to: projectName)
        board.renameBoard(to: boardName)
    }

    private func addColumn() {
        board.addColumn(title: newColumnTitle)
        newColumnTitle = ""
    }
}

private struct ColumnSettingRow: View {
    @Bindable var board: BoardViewModel
    let column: Column
    @State private var title: String
    @FocusState private var isFocused: Bool

    init(board: BoardViewModel, column: Column) {
        self.board = board
        self.column = column
        _title = State(initialValue: column.title)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
            TextField("Column title", text: $title)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { board.renameColumn(column, to: title) }
                .onChange(of: isFocused) { _, focused in
                    if !focused { board.renameColumn(column, to: title) }
                }
            Text("\(board.cards(for: column.id).count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 20)
            Button(role: .destructive) {
                board.deleteColumn(column)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
