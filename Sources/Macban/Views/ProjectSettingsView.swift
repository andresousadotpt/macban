import SwiftUI
import AppKit
import MacbanCore

/// Settings for the open project: rename it and manage the board's columns.
struct ProjectSettingsView: View {
    @Bindable var board: BoardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var projectName: String
    @State private var newColumnTitle = ""

    init(board: BoardViewModel) {
        self.board = board
        _projectName = State(initialValue: board.config.name)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    generalSection
                    columnsSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 520, height: 560)
    }

    private var header: some View {
        HStack {
            Label("Project Settings", systemImage: "gearshape")
                .font(.headline)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(16)
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("General").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            HStack {
                Text("Name")
                    .frame(width: 80, alignment: .leading)
                TextField("Project name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { board.renameProject(to: projectName) }
                    .onChange(of: projectName) { _, value in board.renameProject(to: value) }
            }
            HStack {
                Text("Location")
                    .frame(width: 80, alignment: .leading)
                Text(board.projectURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([board.projectURL])
                }
                .controlSize(.small)
            }
        }
    }

    private var columnsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Columns").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            Text("Drag to reorder. Deleting a column moves its cards to the Backlog.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let backlog = board.backlogColumn {
                HStack {
                    Image(systemName: "tray.full").foregroundStyle(.secondary)
                    Text(backlog.title)
                    Spacer()
                    Text("Backlog").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
            }

            List {
                ForEach(board.flowColumns) { column in
                    ColumnSettingRow(board: board, column: column)
                }
                .onMove { source, destination in
                    board.reorderFlowColumns(fromOffsets: source, toOffset: destination)
                }
            }
            .frame(height: 200)
            .listStyle(.bordered)

            HStack {
                Image(systemName: "plus").foregroundStyle(.secondary)
                TextField("Add column", text: $newColumnTitle)
                    .textFieldStyle(.plain)
                    .onSubmit(addColumn)
                Button("Add", action: addColumn)
                    .disabled(newColumnTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
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

    init(board: BoardViewModel, column: Column) {
        self.board = board
        self.column = column
        _title = State(initialValue: column.title)
    }

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
            TextField("Column title", text: $title)
                .textFieldStyle(.plain)
                .onSubmit { board.renameColumn(column, to: title) }
                .onChange(of: title) { _, value in board.renameColumn(column, to: value) }
            let count = board.cards(for: column.id).count
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Button(role: .destructive) {
                board.deleteColumn(column)
            } label: {
                Image(systemName: "trash").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
