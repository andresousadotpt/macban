import SwiftUI
import AppKit
import MacbanCore

struct BoardScreen: View {
    @Bindable var board: BoardViewModel
    @Environment(AppViewModel.self) private var app
    @Environment(AppPreferences.self) private var preferences

    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            let columns = orderedColumns
            let count = max(columns.count, 1)
            let dividers = CGFloat(max(count - 1, 0))
            let available = geo.size.width - dividers
            let minWidth = preferences.columnWidth.minWidth * preferences.zoomScale
            let width = max(minWidth, available / CGFloat(count))

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Array(columns.enumerated()), id: \.element.id) { index, column in
                        ColumnView(board: board, column: column)
                            .frame(width: width)
                            .background(backlogBackground(for: column))
                        if index < columns.count - 1 {
                            Divider()
                        }
                    }
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    app.closeProject()
                } label: {
                    Label("Close Project", systemImage: "chevron.left")
                }
                .help("Close project")
            }
            ToolbarItem(placement: .principal) {
                projectMenu
            }
        }
        .sheet(item: $board.editTarget) { target in
            CardDetailView(board: board, target: target)
        }
        .sheet(isPresented: $showSettings) {
            ProjectSettingsView(board: board)
        }
    }

    private func backlogBackground(for column: Column) -> Color {
        guard column.kind == .backlog, preferences.highlightBacklog else { return .clear }
        return Color.secondary.opacity(0.08)
    }

    private var otherRecents: [RecentProject] {
        app.recents.filter { $0.path != board.projectURL.path }
    }

    @ViewBuilder
    private var projectMenu: some View {
        Menu {
            projectMenuActions
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Text(board.config.name)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Text(board.board.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    @ViewBuilder
    private var projectMenuActions: some View {
        if !otherRecents.isEmpty {
            Section("Switch Project") {
                ForEach(otherRecents) { recent in
                    Button {
                        app.open(url: recent.url)
                    } label: {
                        Label(recent.name, systemImage: "square.stack.3d.up")
                    }
                }
            }
        }
        Button {
            app.openProject()
        } label: {
            Label("Open Other Project…", systemImage: "folder")
        }
        Button {
            app.newProject()
        } label: {
            Label("New Project…", systemImage: "plus")
        }
        Divider()
        Button {
            showSettings = true
        } label: {
            Label("Project Settings…", systemImage: "gearshape")
        }
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([board.projectURL])
        } label: {
            Label("Reveal in Finder", systemImage: "folder")
        }
    }

    /// Backlog first, then the flow columns in order.
    private var orderedColumns: [Column] {
        var result: [Column] = []
        if let backlog = board.backlogColumn {
            result.append(backlog)
        }
        result.append(contentsOf: board.flowColumns)
        return result
    }
}
